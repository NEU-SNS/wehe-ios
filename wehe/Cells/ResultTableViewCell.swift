//
//  ResultTableViewCell.swift
//  wehe
//
//  Created by Kirill Voloshin on 11/2/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ResultTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var statusTextField: UILabel!
    @IBOutlet weak var dateTextField: UILabel!
    @IBOutlet weak var appThroughputTextField: UILabel!
    @IBOutlet weak var nonAppThroughputTextField: UILabel!
    @IBOutlet weak var appThroughputText: UILabel!
    @IBOutlet weak var nonAppThroughputText: UILabel!
    @IBOutlet weak var areaThresholdLabel: UILabel!
    @IBOutlet weak var areaThresholdValueLabel: UILabel!
    @IBOutlet weak var ks2pThresholdLabel: UILabel!
    @IBOutlet weak var ks2pTHresholdValueLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var serverValueLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var arcepLogo: UIImageView!

    weak var cellDelegate: AlertCell?
    var result: Result?

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func beautify() {
        appThroughputText.text = LocalizedStrings.PreviousResults.appThroughput
        nonAppThroughputText.text = LocalizedStrings.PreviousResults.nonAppThroughput
        reportButton.setTitle(LocalizedStrings.ReplayView.alertArcep, for: .normal)
    }

    private func alert(title: String, message: String) {
        cellDelegate?.showAlert(title: title, message: message)
    }

    @IBAction func reportButtonPressed(_ sender: Any) {
        guard let result = self.result else {
            return
        }
        reportButton.isEnabled = false

        let settings = Globals.settings
        let parameters: Parameters = ["userID": result.userID!, "testID": result.testID!, "historyCount": result.historyCount, "command": "alertArcep"]
        let url = Helper.makeURL(ip: settings.serverIP, port: String(settings.resultsPort), api: "Results")
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString)).responseJSON {response in
            defer {
                self.reportButton.isEnabled = true
                self.reportButton.isHidden = true
                self.arcepLogo.isHidden = true
            }
            if let result = response.result.value {
                let json = JSON(result)
                if json != JSON.null {
                    if let success = json["success"].bool {
                        if !success {
                            print("error")
                            self.alert(title: LocalizedStrings.Generic.error, message: json["error"].string ?? "")
                            print(json)
                        } else {
                            self.result?.reported = true
                            self.alert(title: LocalizedStrings.ReplayView.Alerts.success, message: LocalizedStrings.ReplayView.Alerts.reportSent)
                        }
                    }
                }
            }
        }
    }
}
