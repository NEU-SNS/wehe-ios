//
//  ReplayViewController.swift
//  wehe
//
//  Created by Work on 9/12/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import LinearProgressBar

class ReplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AlertCell, InfoCell, ReplayViewProtocol {

    // MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var statusTextField: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var progressLinearBar: LinearProgressBar!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cancelButton: UIBarButtonItem!

    // debug
    let dpiBeta = true

    var settings: Settings?
    var apps = [App]()
    var results = [Result]()
    var dpiApp: App?
    var portTest = false
    var status: GlobalStatus = .waitingToStart {
        didSet {
            if status == .done {
                stopNoSleepTimer()
                statusLabel.isHidden = true
                statusTextField.isHidden = true
            } else {
                statusLabel.isHidden = false
                statusTextField.isHidden = false
            }
            setIconVisibility()
            updateLeftButton()
            updateRightButton()
        }
    }
    var replayRunning = false {
        didSet {
            backButton.isEnabled = !replayRunning
        }
    }
    var replayQueue = [Int]()
    var currentRunner: ReplayRunner?
    let maxResults = 50

    // for displaying progress
    var totalTests = 0 {
        didSet {
            statusTextField.text = String(format: LocalizedStrings.ReplayView.numberOfTest, testsRan, totalTests)
            updateOverallProgress()
        }
    }
    var testsRan = 0 {
        didSet {
            statusTextField.text = String(format: LocalizedStrings.ReplayView.numberOfTest, testsRan, totalTests)
            updateOverallProgress()
        }
    }

    // change this once the number of replays is no longer constant
    var replaysPerTest = 2

    private weak var timer: Timer?
    private let idleTimeOut = 10.0

    override func viewDidLoad() {
        super.viewDidLoad()
        settings = Globals.settings
        if portTest {
            replaysPerTest = 1
        }

        beautify()

        DispatchQueue.main.async {
            self.loadResults()
            self.prepareQueue()
            // Start replays automatically
            self.startPressed()
        }
        tableView.delegate = self
        tableView.dataSource = self
        iconImageView.isHidden = true
        status = .runningReplays
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roundButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopNoSleepTimer()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let moreInfoViewController = segue.destination as? MoreInfoTableViewController {
            moreInfoViewController.app = dpiApp
        }
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ReplayTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ReplayTableViewCell  else {
            fatalError("The dequeue cell is not of type ReplayTableViewCell")
        }

        cell.cellDelegate = self

        let app = apps[indexPath.row]
        cell.app = app

        return cell
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        if status == .waitingToStart || status == .done {
            cancelButton.title = LocalizedStrings.Generic.cancel
            startPressed()
        }
    }
    @IBAction func cancelTap(_ sender: Any) {
        cancelPressed()
    }
    
    private func hasInconclusiveResults() -> Bool {
        var hasInconclusiveReplays = false
        for app in apps {
            if app.differentiation != nil && app.differentiation == .inconclusive {
                hasInconclusiveReplays = true
                }
            }
        return hasInconclusiveReplays
    }
    
    private func hasDifferentiatedResults() -> Bool {
        var hasDifferentiatedReplays = false
        for app in apps {
            if app.differentiation != nil && app.differentiation == .differentiation {
                    hasDifferentiatedReplays = true
            }
        }
        return hasDifferentiatedReplays
    }

    private func startPressed() {
        if replayQueue.count > 0 {
            status = .runningReplays
            totalTests = replayQueue.count * replaysPerTest
            testsRan = 0
            nextReplay()
            return
        }

        var noReplaysWaiting = true
        var hasInconclusiveReplays = false
        var hasDifferentiatedReplays = false
        for app in apps {
            if app.status != .receivedResults && app.status != .error {
                noReplaysWaiting = false
            }
        }
        
        hasInconclusiveReplays = hasInconclusiveResults()
        hasDifferentiatedReplays = hasDifferentiatedResults()
        
        if noReplaysWaiting {
            let alertMessage = LocalizedStrings.ReplayView.Alerts.wouldYouLikeToRerun
            let alertController = UIAlertController(title: LocalizedStrings.ReplayView.Alerts.reRunTestHuh, message: alertMessage, preferredStyle: UIAlertController.Style.alert)

            if hasInconclusiveReplays {
                alertController.addAction(UIAlertAction(title: LocalizedStrings.ReplayView.Alerts.reRunTestsWithInconclusiveAction, style: UIAlertAction.Style.default, handler: {(_) -> Void in
                    self.cleanUpAndRestart(inconclusiveOnly: true)
                }))
                UILabel.appearance(whenContainedInInstancesOf: [UIAlertController.self]).numberOfLines = 0
            }
            
            if hasDifferentiatedReplays {
                alertController.addAction(UIAlertAction(title: LocalizedStrings.ReplayView.Alerts.reRunDifferentiatedAction, style: UIAlertAction.Style.default, handler: {(_) -> Void in
                    self.cleanUpAndRestart(differentiatedOnly: true)
                }))
                UILabel.appearance(whenContainedInInstancesOf: [UIAlertController.self]).numberOfLines = 0
            }

            alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.cancel, style: UIAlertAction.Style.default, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func cancelPressed() {
        if status == .waitingToStart || status == .done {
             navigationController?.popViewController(animated: true)
            if let runner = self.currentRunner {
                runner.cancelReplay()
            }
        } else {
            let warningMessage = LocalizedStrings.ReplayView.Alerts.warningMessage

            let alertController = UIAlertController(title: LocalizedStrings.ReplayView.Alerts.warning, message: warningMessage, preferredStyle: UIAlertController.Style.alert)

            alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.no, style: UIAlertAction.Style.default, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.yes, style: UIAlertAction.Style.default, handler: {(_) -> Void in
                if let runner = self.currentRunner {
                    runner.cancelReplay()
                }
                 self.navigationController?.popViewController(animated: true)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: UI Methods
    func reloadUI() {
        tableView.reloadData()
        startNoSleepTimer(for: idleTimeOut)
    }

    func updateOverallProgress() {
        let value = Float((status == .done || status == .waitingForResults) ? testsRan : (testsRan - 1)) / Float(totalTests)
        progressLinearBar.progressValue = CGFloat(value * 100)
    }

    func updateAppProgress(for app: App, value: Float) {
        app.progress = CGFloat(value)
        guard let cells = tableView.visibleCells as? [ReplayTableViewCell] else {
            print("replay cells not found")
            return
        }

        for cell in cells where app == cell.app {
            cell.updateCell()
            return
        }
    }

    func updateAppStatus(status: ReplayStatus, atIndex: Int, error: String = "") {
        apps[atIndex].status = status
        if status == .error && error != "" {
            apps[atIndex].errorString = error
        }
        reloadUI()
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))

        self.present(alertController, animated: true, completion: nil)
        saveResults()
    }

    func appInfoTapped(app: App) {
        guard status == .done else {
            return
        }
        dpiApp = app
        performSegue(withIdentifier: "toDPI", sender: nil)
    }

    func receivedResult(app: App, result: Result) {
        if results.count >= maxResults {
            results.removeFirst(results.count + 1 - maxResults)
        }

        Helper.runOnUIThread {
            self.saveResults()
        }
        app.result = result
        reloadUI()

        var othersWaiting = false
        for otherApp in apps {
            if otherApp == app {
                continue
            }

            if otherApp.status == .waitingForResults || otherApp.status == .finishedReplay {
                othersWaiting = true
            }
        }

        if replayQueue.count == 0 && !replayRunning && !othersWaiting {
            status = .done
        }
        //A confirmation replay is needed when the first test detects differentiation

        if settings!.confirmationReplays && app.differentiation! != .noDifferentiation && app.timesRan == 1 {
            replayQueue.append(apps.firstIndex(of: app)!)
            totalTests += replaysPerTest
            app.replaysRan = [ReplayType]()
            Helper.runOnUIThread {
                app.status = .willRerun
                self.reloadUI()
                app.differentiation = nil
                self.updateAppProgress(for: app, value: Float(0))
                self.reloadUI()
                self.status = .confirmationReplays
                self.nextReplay()
            }
        } else {
            // append results only for non-confirmation replays
            results.append(result)
        }

    }

    func replayFinished() {
        replayRunning = false
        iconImageView.image = UIImage(named: "placeholder")
        nextReplay()
    }

    func ranTests(number: Int) {
        testsRan += number
    }

    // MARK: Private methods
    private func setIconVisibility() {
        switch status {
        case .waitingToStart:      iconImageView.isHidden = true
        case .runningReplays:      iconImageView.isHidden = false
        case .waitingForResults:   iconImageView.isHidden = true
        case .confirmationReplays: iconImageView.isHidden = false
        case .done:
            iconImageView.isHidden = true
        }
    }

    private func updateLeftButton() {
        switch status {
        case .waitingToStart: backButton.isEnabled = true
        case .done: backButton.isEnabled = true
        default: backButton.isEnabled = false
        }
    }

    private func updateRightButton() {
        switch status {
        case .waitingToStart:
            startButton.setTitle(LocalizedStrings.ReplayView.start, for: .normal)
            startButton.isHidden = false
        case .runningReplays:
            startButton.isHidden = true
        case .waitingForResults:
            updateOverallProgress()
            startButton.isHidden = true
        case .confirmationReplays:
            startButton.isHidden = true
        case .done:
            updateOverallProgress()
            //check whether there is inconclusive or differentiated tests
            var hasInconclusiveReplays = false
            var hasDifferentiatedReplays = false
            hasInconclusiveReplays = hasDifferentiatedResults()
            hasDifferentiatedReplays = hasInconclusiveResults()
            startButton.setTitle(LocalizedStrings.ReplayView.reRun, for: .normal)
            if hasInconclusiveReplays || hasDifferentiatedReplays {
                startButton.isHidden = false
            } else {
                startButton.isHidden = true
            }
            cancelButton.title = LocalizedStrings.Generic.testDone
        }
    }

    private func cleanUpAndRestart(errorsOnly: Bool = false, inconclusiveOnly: Bool = false, differentiatedOnly: Bool = false) {

        var queue = [Int]()

        for (index, app) in apps.enumerated() {
            if errorsOnly && app.status != .error {
                continue
            }

            if inconclusiveOnly && app.differentiation != .inconclusive {
                continue
            }
            
            if differentiatedOnly && app.differentiation != .differentiation {
                continue
            }

            queue.append(index)
            app.reset()
            testsRan = 0
            updateAppProgress(for: app, value: Float(0))
            reloadUI()
        }

        replayQueue = queue
        totalTests = replayQueue.count * replaysPerTest
        testsRan = 0
        status = .runningReplays
        nextReplay()
    }

    private func loadResults() {
       results = Helper.loadResults()
    }

    private func saveResults() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(results, toFile: Result.ArchiveURL.path)
        if !isSuccessfulSave {
            print("Error saving results")
            print(results)
        }
    }

    private func prepareQueue() {
        replayQueue = Array(0...(apps.count - 1))
    }

    private func nextReplay() {
        guard !replayRunning else {
            print("Replay already running")
            return
        }

        guard replayQueue.count > 0 else {
            var waitinfForResults = false
            for app in apps {
                if app.status == .finishedReplay || app.status == .waitingForResults {
                    waitinfForResults = true
                }
            }

            if waitinfForResults {
                status = .waitingForResults
            } else {
                status = .done
            }

            return
        }

        let index = replayQueue.removeFirst()
        startReplay(index: index)
    }

    private func startReplay(index: Int) {
        replayRunning = true
        let app = apps[index]
        iconImageView.image = UIImage(named: app.icon)
        reloadUI()
        let runner = ReplayRunner(replayView: self, app: app)
        currentRunner = runner
        runner.run()
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
        cancelButton.title = LocalizedStrings.Generic.cancel
    }

    private func roundButton() {
        startButton.layer.cornerRadius = startButton.bounds.size.width * 0.5
        startButton.clipsToBounds = true
        startButton.layer.borderWidth = 2
        startButton.layer.borderColor = Helper.colorFromRGB(r: 54, g: 95, b: 133).cgColor
    }
}

enum GlobalStatus {
    case waitingToStart
    case runningReplays
    case waitingForResults
    case confirmationReplays
    case done

    var description: String {
        switch self {
        case .waitingToStart:      return LocalizedStrings.ReplayView.GlobalStatus.waitingToStart
        case .runningReplays:      return LocalizedStrings.ReplayView.GlobalStatus.runningReplays
        case .waitingForResults:   return LocalizedStrings.ReplayView.GlobalStatus.waitingForResults
        case .confirmationReplays: return LocalizedStrings.ReplayView.GlobalStatus.confirmationReplays
        case .done:                return LocalizedStrings.ReplayView.GlobalStatus.done
        }
    }
}
