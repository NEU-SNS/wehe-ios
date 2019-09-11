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

    override func viewDidLoad() {
        super.viewDidLoad()
        beautify()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // make it so the textview is scrolled to the top once we change the text
        contentsTextView.setContentOffset(.zero, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    private func beautify() {
        backButton.title = LocalizedStrings.Generic.back
        titleLabel.text = LocalizedStrings.aboutWehe.title
        contentsTextView.text = LocalizedStrings.aboutWehe.contents
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
