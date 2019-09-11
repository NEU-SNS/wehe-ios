//
//  ReplayTableViewCell.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/13/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import LinearProgressBar

class ReplayTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameTextField: UILabel!
    @IBOutlet weak var statusTextField: UILabel!
    @IBOutlet weak var potentialThroughputTextField: UILabel!
    @IBOutlet weak var potentialThroughputValueTextField: UILabel!
    @IBOutlet weak var actualThroughputTextField: UILabel!
    @IBOutlet weak var actualThroughputValueTextField: UILabel!
    @IBOutlet weak var differentiationTextField: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var progressBar: LinearProgressBar!
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var arcepIconImageView: UIImageView!

    var app: App? {
        didSet {
            updateCell()
        }
    }
    weak var cellDelegate: (AlertCell & InfoCell)?

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
        addListener()
        if app != nil {
            updateCell()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func updateProgress(value: Float) {
        let cgValue = CGFloat(value)
        guard cgValue > progressBar.progressValue || cgValue == 0 || cgValue == 50 else {
            return
        }

        progressBar.progressValue = cgValue
    }

    private func beautify() {
        differentiationTextField.text = LocalizedStrings.Generic.differentition
        actualThroughputTextField.text = LocalizedStrings.PreviousResults.appThroughput
        potentialThroughputTextField.text = LocalizedStrings.PreviousResults.nonAppThroughput
        reportButton.setTitle(LocalizedStrings.ReplayView.alertArcep, for: .normal)
    }

    private func alert(title: String, message: String) {
        cellDelegate?.showAlert(title: title, message: message)
    }

    @IBAction func reportPressed(_ sender: Any) {
        guard let app = self.app else {
            return
        }
        reportButton.isEnabled = false

        let settings = Globals.settings
        let parameters: Parameters = ["userID": app.userID!, "testID": app.testID!, "historyCount": app.historyCount!, "command": "alertArcep"]
        let url = Helper.makeURL(ip: settings.serverIP, port: String(settings.resultsPort), api: "Results")
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString)).responseJSON {response in
            defer {
                self.reportButton.isEnabled = true
                self.reportButton.isHidden = true
                self.arcepIconImageView.isHidden = true
                self.potentialThroughputTextField.isHidden = false
                self.potentialThroughputValueTextField.isHidden = false
                self.actualThroughputTextField.isHidden = false
                self.actualThroughputValueTextField.isHidden = false
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
                            app.result!.reported = true
                            self.alert(title: LocalizedStrings.ReplayView.Alerts.success, message: LocalizedStrings.ReplayView.Alerts.reportSent)
                        }
                    }
                }
            }
        }
    }

    func updateCell() {
        updateText()
        updateColors()
        updateVisibility()
        updateProgress()
    }

    private func updateProgress() {
        guard app!.progress > progressBar.progressValue || app!.progress == 0 || app!.progress == 50 else {
            return
        }

        progressBar.progressValue = app!.progress
    }

    private func updateText() {
        if let nonAppThrougput = app?.nonAppThroughput {
            potentialThroughputValueTextField.text = String(format: "%.0f Mbps", nonAppThrougput.rounded())
        }

        if let appThroughput = app?.appThroughput {
            actualThroughputValueTextField.text = String(format: "%.0f Mbps", appThroughput.rounded())
        }

        iconImageView.image = UIImage(named: app?.icon ?? "placeholder")
        nameTextField.text = app?.name
        statusTextField.text = app?.getStatusString()

        guard let differentiation = app?.differentiation else {
            return
        }

        switch differentiation {
        case .noDifferentiation:
            statusTextField.text = LocalizedStrings.ReplayView.noDifferentiation
        case .inconclusive:
            if app?.status == .receivedResults {
                statusTextField.text = LocalizedStrings.ReplayView.resultInconclusive
            }
        default:
            break
        }
    }

    private func updateColors() {
        guard let differentiation = app?.differentiation else {
            statusTextField.textColor = UIColor.black
            return
        }

        switch differentiation {
        case .noDifferentiation: statusTextField.textColor = Settings.noDifferentiationColor
        case .inconclusive:
            if app?.status == .receivedResults {
                statusTextField.textColor = UIColor.orange
            }
        default:
            if app?.status == .error {
                statusTextField.textColor = UIColor.red
            } else {
                statusTextField.textColor = UIColor.black
            }
        }
    }

    private func updateVisibility() {
        if app?.differentiation != nil || app?.status == .willRerun || app?.status == .waitingForResults {
            progressBar.isHidden = true
        } else {
            progressBar.isHidden = false
        }

        if let differentiation = app?.differentiation, differentiation == .differentiation {
            if !Helper.isFrenchLocale() || app?.result?.reported ?? false {
                reportButton.isHidden = true
                arcepIconImageView.isHidden = true
                potentialThroughputTextField.isHidden = false
                potentialThroughputValueTextField.isHidden = false
                actualThroughputTextField.isHidden = false
                actualThroughputValueTextField.isHidden = false
                statusTextField.isHidden = true
                differentiationTextField.isHidden = false
            } else {
                statusTextField.isHidden = true
                differentiationTextField.isHidden = false
                reportButton.isHidden = false
                arcepIconImageView.isHidden = false
            }
            infoImageView.isHidden = false
        } else {
            infoImageView.isHidden = true
            reportButton.isHidden = true
            arcepIconImageView.isHidden = true
            statusTextField.isHidden = false
            differentiationTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
        }

        if app?.status == .error {
            progressBar.isHidden = true
        }
    }

    private func addListener() {
        guard let infoImageView = infoImageView else {
            return
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ReplayTableViewCell.infoTapped))
        infoImageView.isUserInteractionEnabled = true
        infoImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func infoTapped() {
        cellDelegate?.appInfoTapped(app: app!)
    }
}

protocol AlertCell: class {
    func showAlert(title: String, message: String)
}

protocol InfoCell: class {
    func appInfoTapped(app: App)
}
