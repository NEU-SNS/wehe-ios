//
//  MoreInfoTableViewController
//  wehe
//
//  Created by Ivan Chen on 4/9/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MoreInfoTableViewController: UITableViewController {

    var settings: Settings?
    var app: App?
    var testID = 2

    private var dpiInfoResultText: String?
    private var haveConnection: Bool = false

    @IBOutlet weak var backButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        beautify()
        settings = Globals.settings

        tableView.estimatedRowHeight = 140
        tableView.tableFooterView = UIView()

        requestDPIResult()
    }

    private func requestDPIResult() {
        guard let userID = settings?.randomID,
            let replayName = app?.name else {
                print("error getting initial variables")
                haveConnection = false
                return
        }
        let parameters: Parameters = ["command": "DPIrule",
                                      "userID": userID,
                                      "carrierName": Helper.getCarrier() ?? "nil",
                                      "replayName": replayName]
        let url = Helper.makeURL(ip: settings!.serverIP, port: String(settings!.resultsPort), api: "Results")
        if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? DPIInfoTableViewCell {
            cell.waiting()
        }
        print(url)
        print(parameters)
        Alamofire.request(url, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success:
                print(response.result.value!)
                self.haveConnection = true
                let json = JSON(response.result.value!)
                if json["success"] == true {
                    var dpiRuleStr = json["response"]["DPIrule"].stringValue
                    dpiRuleStr = dpiRuleStr.replacingOccurrences(of: "\'", with: "\"")
                    do {
                        if let data = dpiRuleStr.data(using: .utf8) {
                            dpiRuleStr = (try JSON(data: data).dictionary?.values.first!.stringValue)!
                        }
                    } catch {
                        dpiRuleStr = LocalizedStrings.MoreInfo.unableToParseResult
                    }

                    self.dpiInfoResultText = String(format: LocalizedStrings.MoreInfo.dpiInfoResultText,
                                                    json["response"]["timestamp"].stringValue,
                                                    dpiRuleStr,
                                                    json["response"]["numTests"].stringValue)
                } else {
                    self.dpiInfoResultText = LocalizedStrings.MoreInfo.noResultsFound
                }
            case .failure:
                self.haveConnection = false
                self.dpiInfoResultText = LocalizedStrings.MoreInfo.unableToContactServer
            }
            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }
    }

    private func beautify() {
        title = LocalizedStrings.MoreInfo.title
        backButton.title = LocalizedStrings.Generic.back
    }

    private func resetDPIHistory() {
        guard let userID = settings?.randomID,
            let replayName = app?.name else {
                print("error getting initial variables")
                return
        }
        let parameters: Parameters = ["command": "DPIreset",
                                      "userID": userID,
                                      "carrierName": Helper.getCarrier() ?? "nil",
                                      "replayName": replayName]
        let url = Helper.makeURL(ip: settings!.serverIP, port: String(settings!.resultsPort), api: "Results")
        Alamofire.request(url, parameters: parameters).responseJSON { _ in
            // do nothing
        }

        performSegue(withIdentifier: "unwindSegueToAppTableVC", sender: self)
    }

    // MARK: - Actions

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func startDPITest(_ sender: Any) {
        if !haveConnection {
            requestDPIResult()
        }
    }

    @IBAction func restartDPITest(_ sender: Any) {
        let alertController = UIAlertController(title: LocalizedStrings.MoreInfo.resetDPIProgress,
                                                message: LocalizedStrings.MoreInfo.youWillLoseProgress,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.cancel, style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: LocalizedStrings.Generic.yes, style: .default, handler: { _ in
            self.resetDPIHistory()
        }))

        self.present(alertController, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 90.0
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DiffResultCell") as? ReplayTableViewCell else {
                break
            }
            if let app = app {
                cell.app = app
            }

            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BitrateInfoCell") as? BitrateInfoTableViewCell else {
                break
            }
            cell.textView.text = LocalizedStrings.MoreInfo.bitrateInfo
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DPIInfoCell") as? DPIInfoTableViewCell else {
                break
            }

            if let dpiInfoText = dpiInfoResultText {
                cell.resultTextView.text = LocalizedStrings.MoreInfo.previousResult + dpiInfoText
                cell.haveResult(haveConnection: haveConnection)
            } else {
                cell.waiting()
            }
            return cell
        default:
            return UITableViewCell()
        }
        return UITableViewCell()
    }

    // MARK: - Segues
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DPIAnalysisViewController {
            destination.app = app
            destination.moreInfoVCDelegate = self
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return haveConnection
    }
}
