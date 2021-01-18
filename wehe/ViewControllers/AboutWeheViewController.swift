//
//  AboutWeheViewController.swift
//  wehe
//
//  Created by Work on 10/31/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit

class AboutWeheViewController: UIViewController {

    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentsTextView: UITextView!
    
    @IBOutlet weak var versionNumber: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beautify()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // make it so the textview is scrolled to the top once we change the text
        contentsTextView.setContentOffset(.zero, animated: true)
    }

    private func beautify() {
        backButton.title = LocalizedStrings.Generic.back
        titleLabel.text = LocalizedStrings.aboutWehe.title
        contentsTextView.text = LocalizedStrings.aboutWehe.contents
        var appVersion: String
        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let bundlebuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                appVersion = bundleVersion + bundlebuild
            } else {
                appVersion = bundleVersion
            }
        } else {
            appVersion = "1.0"
        }
        versionNumber.text = appVersion
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
