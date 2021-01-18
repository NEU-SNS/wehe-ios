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
    var labelDefaultColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor.label
        } else {
            return UIColor.black
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
        if app?.isPortTest ?? false {
            // DEBUG
            actualThroughputTextField.text = LocalizedStrings.App.portThroughput
            potentialThroughputTextField.text = LocalizedStrings.App.baselineThroughput
        } else {
            actualThroughputTextField.text = LocalizedStrings.PreviousResults.appThroughput
            potentialThroughputTextField.text = LocalizedStrings.PreviousResults.nonAppThroughput
        }
        reportButton.setTitle(LocalizedStrings.ReplayView.alertArcep, for: .normal)
    }

    private func alert(title: String, message: String) {
        cellDelegate?.showAlert(title: title, message: message)
    }

    @IBAction func reportPressed(_ sender: Any) {
        showArcepPage()
    }

    func showArcepPage() {
        if let url = URL(string: "https://jalerte.arcep.fr/jalerte/?2") {
            UIApplication.shared.open(url)
        }
    }

    func updateCell() {
        beautify()
        updateVisibility()
        updateText()
        updateColors()
        updateProgress()
    }

    private func updateProgress() {
        guard app!.progress > progressBar.progressValue || app!.progress == 0 || app!.progress == 50 else {
            return
        }

        progressBar.progressValue = app!.progress
    }

    private func updateText() {
        if let nonAppThrougput = app?.nonAppThroughput, let appThroughput = app?.appThroughput {
            potentialThroughputValueTextField.text = String(format: "%.1f " + LocalizedStrings.Generic.mbps, nonAppThrougput)
            actualThroughputValueTextField.text = String(format: "%.1f " + LocalizedStrings.Generic.mbps, appThroughput)
            if appThroughput > nonAppThrougput {
                app?.prioritized = true
            } else {
                app?.prioritized = false
            }
        }

        iconImageView.image = UIImage(named: app?.icon ?? "placeholder")
        var appname = app?.name
        if Helper.isFrenchLocale() {
            appname = appname?.replacingOccurrences(of: "MB)", with: "Mo)")
        }
        nameTextField.text = appname
        statusTextField.text = app?.getStatusString()

        guard let differentiation = app?.differentiation else {
            return
        }

        switch differentiation {
        case .noDifferentiation:
            differentiationTextField.text = LocalizedStrings.Generic.noDifferentition
        case .inconclusive:
            if app?.status == .error && app?.errorString == LocalizedStrings.errors.connectionBlockError {
                differentiationTextField.text = LocalizedStrings.Generic.inconclusiveNoRerun
            } else {
                differentiationTextField.text = LocalizedStrings.Generic.inconclusive
            }
        case .differentiation:
            differentiationTextField.text = LocalizedStrings.Generic.differentition
        }
    }

    private func updateColors() {
        guard let differentiation = app?.differentiation else {
            statusTextField.textColor = labelDefaultColor
            return
        }

        switch differentiation {
        case .noDifferentiation: differentiationTextField.textColor = Settings.noDifferentiationColor
        case .inconclusive:
            differentiationTextField.textColor = UIColor.orange
        case .differentiation:differentiationTextField.textColor = UIColor.red
        }
    }

    private func updateVisibility() {
        // control progress bar
        if app?.differentiation != nil || app?.status == .willRerun || app?.status == .waitingForResults {
            progressBar.isHidden = true
        } else {
            progressBar.isHidden = false
            statusTextField.isHidden = false
            infoImageView.isHidden = true
            reportButton.isHidden = true
            arcepIconImageView.isHidden = true
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            differentiationTextField.isHidden = true
        }

        if app?.status == .receivedResults { // test finished, received results
            if app?.differentiation == .differentiation {// detected differentiation
                if Helper.isFrenchLocale() { // French version, show Arcep button
                    reportButton.isHidden = false
                    arcepIconImageView.isHidden = false
                } else { // non French version, no arcep button
                    reportButton.isHidden = true
                    arcepIconImageView.isHidden = true
                }
                infoImageView.isHidden = false // show more info button
            } else if app?.differentiation == .noDifferentiation { // no diff
                infoImageView.isHidden = true
                reportButton.isHidden = true
                arcepIconImageView.isHidden = true
            } else { // inconclusive
                infoImageView.isHidden = true
                reportButton.isHidden = true
                arcepIconImageView.isHidden = true
            }
            actualThroughputTextField.isHidden = false
            actualThroughputValueTextField.isHidden = false
            potentialThroughputTextField.isHidden = false
            potentialThroughputValueTextField.isHidden = false
            statusTextField.isHidden = true
            differentiationTextField.isHidden = false
        } else if app?.status == .error && app?.errorString == LocalizedStrings.errors.connectionBlockError {
            // when failed to connect sockets/the test is blocked
            statusTextField.isHidden = true
            progressBar.isHidden = true
            app?.differentiation = .differentiation
            infoImageView.isHidden = false // show more info button
            differentiationTextField.isHidden = false
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            if Helper.isFrenchLocale() { // French version, show Arcep button
                reportButton.isHidden = false
                arcepIconImageView.isHidden = false
            } else { // non French version, no arcep button
                reportButton.isHidden = true
                arcepIconImageView.isHidden = true
            }
        } else if app?.status == .error && app?.errorString == LocalizedStrings.ReplayRunner.errorReceivingPackets {
            // when failed to receive packets after establishing the connection
            if app?.isPortTest ?? false {
                app?.differentiation = .differentiation
                if Helper.isFrenchLocale() { // French version, show Arcep button
                    reportButton.isHidden = false
                    arcepIconImageView.isHidden = false
                } else { // non French version, no arcep button
                    reportButton.isHidden = true
                    arcepIconImageView.isHidden = true
                }
            } else {
                app?.differentiation = .inconclusive
            }
            infoImageView.isHidden = false // show more info button
            differentiationTextField.isHidden = false
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            statusTextField.isHidden = true
            progressBar.isHidden = true
        } else if app?.status == .error { // other errors
            statusTextField.isHidden = true
            progressBar.isHidden = true
            app?.differentiation = .inconclusive
            infoImageView.isHidden = false // show more info button
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            differentiationTextField.isHidden = false
            reportButton.isHidden = true
            arcepIconImageView.isHidden = true
        } else { // test in progress
            infoImageView.isHidden = true
            statusTextField.isHidden = false
            differentiationTextField.isHidden = true
            potentialThroughputTextField.isHidden = true
            potentialThroughputValueTextField.isHidden = true
            actualThroughputTextField.isHidden = true
            actualThroughputValueTextField.isHidden = true
            reportButton.isHidden = true
            arcepIconImageView.isHidden = true
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
