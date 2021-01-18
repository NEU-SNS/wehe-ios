//
//  WebViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 12/5/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet weak var mainWebView: UIWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!

    var webUrl = "http://wehe.meddle.mobi/globalStats.html"

    override func viewDidLoad() {
        super.viewDidLoad()

        if Helper.isFrenchLocale() {
            webUrl = "https://wehe.meddle.mobi/StatsFrance.html"
        }

        beautify()
        makeRequest()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func makeRequest() {
        let u = URL(string: webUrl)
        guard let url = u else {
            handleError()
            return
        }

        let request = URLRequest(url: url)
        let session =  URLSession.shared

        let task = session.dataTask(with: request) { (_, err, _) in

            guard err != nil else {
                Helper.runOnUIThread {
                    self.handleError()
                }
                return
            }

            Helper.runOnUIThread {
                self.mainWebView.loadRequest(request)
            }
        }

        task.resume()
    }

    private func handleError() {
        let warningMessage = LocalizedStrings.ConsentForm.warnindMessage

        let alertController = UIAlertController(title: LocalizedStrings.Generic.error, message: warningMessage, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: LocalizedStrings.ConsentForm.backToMenu, style: UIAlertAction.Style.default, handler: {(_) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    private func beautify() {
        backButton.title = LocalizedStrings.Generic.back
    }
    @IBAction func backButtonPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
