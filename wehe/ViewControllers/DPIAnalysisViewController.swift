//
//  DPIAnalysisViewController.swift
//  wehe
//
//  Created by Ivan Chen on 4/13/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Foundation

class DPIAnalysisViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AlertCell, InfoCell, ReplayViewProtocol {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    @IBOutlet weak var replayNameTextField: UILabel!
    @IBOutlet weak var statusTextField: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var currentTestLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    var settings: Settings?
    var app: App?
    var status: DPIStatus = .requestingNextTest {
        didSet {
            if status == .done {
                stopNoSleepTimer()
            }
            statusTextField.text = status.description
            updateLeftButton()
            updateRightButton()
        }
    }
    
    var currentRunner: ReplayRunner?
    weak var moreInfoVCDelegate: MoreInfoTableViewController?
    
    private var currentRegion: TestRegion = TestRegion.empty()
    private var testedRegion: TestRegion = TestRegion.empty()
    private var diff = false
    
    private var histories: [History] = []
    
    private weak var timer: Timer?
    private let idleTimeOut = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beautify()
        
        settings = Globals.settings
        
        tableView.delegate = self
        tableView.dataSource = self
        
        statusTextField.text = status.description
        if let app = app {
            replayNameTextField.text = app.name
            iconImageView.image = UIImage(named: app.icon)
        }
        
        self.requestNextAnalysis()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopNoSleepTimer()
    }
    
    private func startPressed() {
        histories = []
        replayNameTextField.text = app?.name
        reloadUI()
        requestNextAnalysis()
    }
    
    private func cancelPressed() {
        let alertController = UIAlertController(title: LocalizedStrings.Generic.warning,
                                                message: LocalizedStrings.DPIAnalysis.alert.actionWillStopActiveTest,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.no, style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.yes, style: .default, handler: {(_) -> Void in
            if let runner = self.currentRunner {
                runner.cancelReplay()
            }
            
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func requestNextAnalysis() {
        status = .requestingNextTest
        guard let userID = settings?.randomID,
            let replayName = app?.name,
            let serverIP = settings?.serverIP,
            let resultPort = settings?.resultsPort,
            let historyCount = app?.historyCount,
            let testID = moreInfoVCDelegate?.testID else {
                print("error unwrapping optionals")
                status = .error
                return
        }
        let parameters: Parameters = ["command": "DPIanalysis",
                                      "userID": userID,
                                      "carrierName": Helper.getCarrier() ?? "nil",
                                      "replayName": replayName,
                                      "historyCount": historyCount,
                                      "testID": testID,
                                      "testedLeft": testedRegion.left,
                                      "testedRight": testedRegion.right,
                                      "diff": diff ? "T" : "F"]
        let url = Helper.makeURL(ip: serverIP, port: String(resultPort), api: "Results")
        print(url)
        AF.request(url, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
                if json != JSON.null && json["success"].boolValue {
                    let testRegionLeft = json["response"]["testRegionLeft"].intValue
                    let testRegionRight = json["response"]["testRegionRight"].intValue
                    let testPacket = json["response"]["testPacket"].stringValue.components(separatedBy: "_")
                    let side: TestRegion.Side = testPacket[0] == "C" ? .client : .server
                    if side == .server {
                        // Not yet supported feature, to handle server side differently
                    }
                    if json["response"]["DPIrule"].exists() {
                        self.receivedMatchingString(result: json["response"]["DPIrule"].first?.1.dictionary?.values.first?.stringValue ?? "")
                        return
                    }
                    let packetNum = Int(testPacket[1]) ?? -1
                    self.currentRegion = TestRegion(side: side,
                                                    numPacket: packetNum,
                                                    left: testRegionLeft,
                                                    right: testRegionRight)
                    self.startDPIAnalysis(testRegion: self.currentRegion)
                } else {
                    self.status = .error
                    print("error unsuccessful")
                    return
                }
                
            case .failure:
                print("unable to connect to server")
                self.status = .unableToConnectToServer
                return
            }
        }
    }
    
    private func startDPIAnalysis(testRegion: TestRegion) {
        status = .runningAnalysis
        replayNameTextField.text = String(format: LocalizedStrings.DPIAnalysis.replayName,
                                          testRegion.numPacket,
                                          testRegion.left,
                                          testRegion.right)
        guard let testID = moreInfoVCDelegate?.testID,
            let app = app else {
                status = .error
                return
        }
        let runner = ReplayRunner(replayView: self, app: app, dpiTestID: testID)
        currentRunner = runner
        runner.run(testRegion: testRegion)
    }
    
    private func receivedMatchingString(result: String) {
        status = .done
        let alertController = UIAlertController(title: LocalizedStrings.DPIAnalysis.alert.finished,
                                                message: String(format: LocalizedStrings.DPIAnalysis.alert.matchingKeyword,
                                                                result),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalizedStrings.DPIAnalysis.alert.done, style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func goBackToMoreInfoVC(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToMoreInfoVC", sender: self)
    }
    
    private func updateLeftButton() {
        backButton.isEnabled = status == .done || status == .error || status == .unableToConnectToServer
    }
    
    private func updateRightButton() {
        if status == .runningAnalysis || status == .requestingNextTest {
            rightButton.title = LocalizedStrings.Generic.cancel
        } else if status == .error || status == .unableToConnectToServer {
            rightButton.title = LocalizedStrings.DPIAnalysis.reRun
        } else {
            rightButton.title = LocalizedStrings.DPIAnalysis.start
        }
    }
    
    private func startNoSleepTimer(for seconds: Double) {
        UIApplication.shared.isIdleTimerDisabled = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            self.stopNoSleepTimer()
        }
    }
    
    private func stopNoSleepTimer() {
        timer?.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func beautify() {
        title = LocalizedStrings.DPIAnalysis.title
        backButton.title = LocalizedStrings.Generic.back
        currentTestLabel.text = "\(LocalizedStrings.ReplayView.currentTest):"
        statusLabel.text = "\(LocalizedStrings.ReplayView.status):"
    }
    
    // MARK: - Actions
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        if status == .done || status == .error || status == .unableToConnectToServer {
            startPressed()
        } else {
            cancelPressed()
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return histories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReplayTableViewCell", for: indexPath) as? ReplayTableViewCell else {
            status = .error
            return UITableViewCell()
        }
        let history = histories[histories.count - (indexPath.row + 1)]
        cell.cellDelegate = self
        cell.iconImageView.image = UIImage(named: history.appIcon)
        cell.nameTextField.text = String(format: "P%d - [%d, %d]",
                                         history.packetNum,
                                         history.left,
                                         history.right)
        
        if history.differentiation == .differentiation {
            cell.potentialThroughputTextField.isHidden = false
            cell.potentialThroughputValueTextField.isHidden = false
            cell.actualThroughputTextField.isHidden = false
            cell.actualThroughputValueTextField.isHidden = false
            cell.statusTextField.isHidden = true
            cell.differentiationTextField.isHidden = false
            cell.potentialThroughputValueTextField.text = String(format: "%.0f Mbps", history.nonAppThroughput.rounded())
            cell.actualThroughputValueTextField.text = String(format: "%.0f Mbps", history.appThroughput.rounded())
        } else {
            cell.differentiationTextField.isHidden = true
            cell.potentialThroughputTextField.isHidden = true
            cell.potentialThroughputValueTextField.isHidden = true
            cell.actualThroughputTextField.isHidden = true
            cell.actualThroughputValueTextField.isHidden = true
            cell.statusTextField.isHidden = false
            cell.statusTextField.textColor = Settings.noDifferentiationColor
            cell.statusTextField.text = LocalizedStrings.Generic.noDifferentition
        }
        
        cell.infoImageView.isHidden = true
        return cell
    }
    
    // MARK: - ReplayViewProtocol
    func reloadUI() {
        tableView.reloadData()
        startNoSleepTimer(for: idleTimeOut)
    }
    
    func getProgress() -> Float {
        return progressView.progress
    }
    
    func updateProgress(value: Float) {
        progressView.setProgress(value, animated: false)
    }
    
    func replayFinished() {
        if app?.status == .error {
            status = .error
        }
    }
    
    func receivedResult(app: App, result: Result) {
        testedRegion = currentRegion
        diff = result.differentiation == .differentiation
        moreInfoVCDelegate?.testID += 1
        
        histories.append(History(left: testedRegion.left,
                                 right: testedRegion.right,
                                 packetNum: testedRegion.numPacket,
                                 nonAppThroughput: app.nonAppThroughput!,
                                 appThroughput: app.appThroughput!,
                                 differentiation: app.differentiation!,
                                 appIcon: app.icon))
        reloadUI()
        
        requestNextAnalysis()
    }
    
    func updateOverallProgress() {
    }
    
    func updateAppProgress(for app: App, value: Float) {
        guard let cells = tableView.visibleCells as? [ReplayTableViewCell] else {
            print("replay cells not found")
            return
        }
        
        for cell in cells where cell.app != nil && cell.app! == app {
            cell.updateProgress(value: value)
            return
        }
    }
    
    func ranTests(number: Int) {
        print("Ran test: " + String(number))
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func appInfoTapped(app: App) {
        // don't do anything
    }
}

enum DPIStatus {
    case requestingNextTest
    case runningAnalysis
    case unableToConnectToServer
    case error
    case done
    
    var description: String {
        switch self {
        case .requestingNextTest:       return LocalizedStrings.DPIAnalysis.status.requestingNextTest
        case .runningAnalysis:          return LocalizedStrings.DPIAnalysis.status.runningAnalysis
        case .unableToConnectToServer:  return LocalizedStrings.DPIAnalysis.status.unableToContactServer
        case .error:                    return LocalizedStrings.DPIAnalysis.status.error
        case .done:                     return LocalizedStrings.DPIAnalysis.status.done
        }
    }
}

struct TestRegion {
    enum Side {
        case client
        case server
    }
    let side: Side
    let numPacket: Int
    let left: Int
    let right: Int
    
    static func empty() -> TestRegion {
        return TestRegion(side: .client, numPacket: -1, left: -1, right: -1)
    }
}

struct History {
    let left: Int
    let right: Int
    let packetNum: Int
    
    let nonAppThroughput: Double
    let appThroughput: Double
    let differentiation: DifferentiationStatus
    let appIcon: String
}
