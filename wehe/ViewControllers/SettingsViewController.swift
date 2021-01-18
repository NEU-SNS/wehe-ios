//
//  SettingsViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/8/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import DropDown

class SettingsViewController: UIViewController, UITextFieldDelegate {

    // MARK: Properties

    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var areaTestTextField: UITextField!
    @IBOutlet weak var pValueTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var confirmationReplaysSwitch: UISwitch!
    @IBOutlet weak var defaultSettingsSwitch: UISwitch!

    @IBOutlet weak var settingsTitle: UINavigationItem!
    @IBOutlet weak var selectServerLabel: UILabel!
    @IBOutlet weak var runMultiTestLabel: UILabel!
    @IBOutlet weak var areaTextThresholdPercentageLabel: UILabel!
    @IBOutlet weak var ks2PValueTestThresholdPrecentageLabel: UILabel!
    @IBOutlet weak var useDefaultValuesLabel: UILabel!

    var settings: Settings?

    override func viewDidLoad() {
        super.viewDidLoad()
        settings = Globals.settings
        beautify()

        // handle text input
        areaTestTextField.delegate = self
        pValueTextField.delegate = self

        loadSettings()
        updateSaveButton()
        addGestureRecognizer()
    }

    // MARK: - Navigation

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButton()
    }

    // MARK: Actions

    @IBAction func defaultFlipped(_ sender: Any) {
        defaultSwitchFlipped()
    }

    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func savePressed(_ sender: Any) {
        // These text fields should never be empty when this is called
        // but defaults are provided just in case
        if let settings = settings {
            settings.server = serverLabel.text ?? Settings.DefaultSettings.server
            settings.serverIP = Helper.dnsLookup(hostname: settings.server) ?? settings.server
            print("server ip", settings.serverIP)
            settings.confirmationReplays = confirmationReplaysSwitch.isOn

            settings.areaThreshold = (Double(areaTestTextField.text!) ?? Settings.DefaultSettings.areaThreshold * 100) / 100
            settings.pValueThreshold = (Double(pValueTextField.text!) ?? Settings.DefaultSettings.pValueThreshold * 100) / 100
            settings.defaultThresholds = defaultSettingsSwitch.isOn
        }

        Globals.settings = settings!
        dismiss(animated: true, completion: nil)
    }

    // MARK: Private methods
    private func loadSettings() {

        serverLabel.text = settings!.server
        confirmationReplaysSwitch.isOn = settings!.confirmationReplays
        areaTestTextField.text = String(Double(settings!.areaThreshold * 100))
        pValueTextField.text = String(Double(settings!.pValueThreshold * 100))
        defaultSettingsSwitch.isOn = settings!.defaultThresholds

        defaultSwitchFlipped()
    }

    private func updateSaveButton() {
        let serverText = serverLabel.text ?? ""
        let areaText = areaTestTextField.text ?? ""
        let pValueText = pValueTextField.text ?? ""

        let areaValue = Int(areaText) ?? Int(Settings.DefaultSettings.areaThreshold * 100)
        let pValue = Int(pValueText) ?? Int(Settings.DefaultSettings.pValueThreshold * 100)

        let areaInBounds = areaValue > 0 && areaValue <= 100
        let pValueInBounds = pValue > 0 && pValue <= 100

        saveButton.isEnabled = !serverText.isEmpty && !areaText.isEmpty && !pValueText.isEmpty && areaInBounds && pValueInBounds
    }

    private func beautify() {
        settingsTitle.title = LocalizedStrings.Settings.settings
        saveButton.title = LocalizedStrings.Settings.save
        selectServerLabel.text = LocalizedStrings.Settings.selectServer
        runMultiTestLabel.text = LocalizedStrings.Settings.runMultipleTests
        areaTextThresholdPercentageLabel.text = LocalizedStrings.Settings.areaTestThreshold
        ks2PValueTestThresholdPrecentageLabel.text = LocalizedStrings.Settings.ks2PValue
        useDefaultValuesLabel.text = LocalizedStrings.Settings.useDefaultValues
    }

    private func defaultSwitchFlipped() {
        if defaultSettingsSwitch.isOn {
            areaTestTextField.isEnabled = false
            areaTestTextField.alpha = 0.5
            pValueTextField.isEnabled = false
            pValueTextField.alpha = 0.5
            serverLabel.isEnabled = false
            serverLabel.alpha = 0.5
            selectServerLabel.isEnabled = false
            selectServerLabel.alpha = 0.5
            serverLabel.text = Settings.DefaultSettings.server
            areaTextThresholdPercentageLabel.alpha = 0.5
            ks2PValueTestThresholdPrecentageLabel.alpha = 0.5
            areaTestTextField.text = String(Int(Settings.DefaultSettings.areaThreshold * 100))
            pValueTextField.text = String(Int(Settings.DefaultSettings.pValueThreshold * 100))
            serverLabel.isUserInteractionEnabled = false
        } else {
            areaTestTextField.isEnabled = true
            pValueTextField.isEnabled = true
            areaTestTextField.alpha = 1
            pValueTextField.alpha = 1
            areaTextThresholdPercentageLabel.alpha = 1
            ks2PValueTestThresholdPrecentageLabel.alpha = 1
            serverLabel.isEnabled = true
            serverLabel.alpha = 1
            selectServerLabel.isEnabled = true
            selectServerLabel.alpha = 1
            serverLabel.isUserInteractionEnabled = true
        }
    }

    private func addGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.serverTapped(_:)))
        serverLabel.addGestureRecognizer(tap)
    }

    @objc private func serverTapped(_ sender: AnyObject) {
        let dropDown = DropDown()

        dropDown.anchorView = serverLabel

        let customKeyword = LocalizedStrings.Settings.custom

        dropDown.dataSource = Settings.DefaultSettings.servers + [customKeyword]

        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if item != customKeyword {
                self.serverLabel.text = Settings.DefaultSettings.servers[index]
            } else {
                self.promptForInput()
            }
        }

        dropDown.show()
        return
    }

    private func promptForInput() {
        let alertController = UIAlertController(title: LocalizedStrings.Settings.customServer, message: LocalizedStrings.Settings.customServerUrl, preferredStyle: .alert)

        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: LocalizedStrings.Generic.enter, style: .default) { (_) in

            let server = alertController.textFields?[0].text
            self.serverLabel.text = server
        }

        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: LocalizedStrings.Generic.cancel, style: .cancel) { (_) in }

        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = Settings.DefaultSettings.server
        }

        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        //finally presenting the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
}

struct Globals {
    static var settings = Settings()
}
