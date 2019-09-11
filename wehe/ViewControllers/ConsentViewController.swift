//
//  ConsentViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/8/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit

class ConsentViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var consentFormItem: UINavigationItem!
    @IBOutlet weak var consentTextView: UITextView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    var settings: Settings?
    var scrolledThrough = false {
        didSet {
            if scrolledThrough {
//                arcepSwitch.isEnabled = true
//                arcepSwitchLabel.isEnabled = true
//                neuSwitch.isEnabled = true
//                neuSwitchLabel.isEnabled = true
                updateAcceptButton()
            }
        }
    }

    override func viewDidLoad() {
        beautify()
        consentTextView.delegate = self
        settings = Globals.settings

        scrolledThrough = settings!.consent

//        neuStackView.isHidden = !Helper.isFrenchLocale()
//        arcepStackView.isHidden = !Helper.isFrenchLocale()
//
//        neuSwitch.isOn = settings!.consent || !Helper.isFrenchLocale()
//        arcepSwitch.isOn = settings!.consent || !Helper.isFrenchLocale()
//        arcepSwitch.isEnabled = settings!.consent
//        arcepSwitchLabel.isEnabled = settings!.consent
//        neuSwitch.isEnabled = settings!.consent
//        neuSwitchLabel.isEnabled = settings!.consent
        updateAcceptButton()

//        neuSwitch.addTarget(self, action: #selector(updateAcceptButton), for: UIControlEvents.valueChanged)
//        arcepSwitch.addTarget(self, action: #selector(updateAcceptButton), for: UIControlEvents.valueChanged)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // make it so the textview is scrolled to the top once we change the text
        consentTextView.setContentOffset(.zero, animated: true)
        let textHeight = consentTextView.contentSize.height
        scrolledThrough = scrolledThrough || !(textHeight > self.consentTextView.bounds.height)
        updateAcceptButton()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
            scrolledThrough = true
        }
    }

    // MARK: Actions
    @IBAction func declineForm() {
        //let defaults = UserDefaults.standard
        //defaults.set(false, forKey: Settings.defaultKeys.consent)
        if let settings = settings {
            settings.consent = false
        } else {
            print("Something went wrong when saving consent setting")
        }

        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }

    @IBAction func acceptForm() {

        //let defaults = UserDefaults.standard
        //defaults.set(true, forKey: Settings.defaultKeys.consent)
        if let settings = settings {
            settings.consent = true
        } else {
            print("Something went wrong when saving consent setting")
        }
        dismiss(animated: true, completion: nil)
    }

    private func beautify() {
        consentFormItem.title = LocalizedStrings.ConsentForm.consentForm
        consentTextView.text = LocalizedStrings.ConsentForm.consentText
        declineButton.setTitle(LocalizedStrings.ConsentForm.decline, for: .normal)
        acceptButton.setTitle(LocalizedStrings.ConsentForm.accept, for: .normal)
//        neuSwitchLabel.text = LocalizedStrings.ConsentForm.neuLabel
//        arcepSwitchLabel.text = LocalizedStrings.ConsentForm.arcepLabel
    }

    @objc
    private func updateAcceptButton() {
//        acceptButton.isEnabled = arcepSwitch.isOn && neuSwitch.isOn && scrolledThrough
        acceptButton.isEnabled = scrolledThrough
    }

}
