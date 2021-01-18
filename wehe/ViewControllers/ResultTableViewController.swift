//
//  ResultTableViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 11/2/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import SafariServices

class ResultTableViewController: UITableViewController, AlertCell {

    @IBOutlet weak var previousResultsTitle: UINavigationItem!

    var apps = [App]()
    var results = [Result]()
    var settings: Settings?

    override func viewDidLoad() {
        super.viewDidLoad()
        settings = Globals.settings

        beautify()
        apps = loadApps()
        results = Helper.loadResults()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.estimatedRowHeight = 214
        tableView.rowHeight = UITableView.automaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ResultTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ResultTableViewCell  else {
            fatalError("The dequeue cell is not of type ResultTableViewCell")
        }

        let result = results[indexPath.row]
        cell.result = result
        cell.cellDelegate = self

        if Helper.isFrenchLocale() && !result.reported && result.differentiation == .differentiation {
            cell.reportButton.isHidden = false
            cell.arcepLogo.isHidden = false
        } else {
            cell.reportButton.isHidden = true
            cell.arcepLogo.isHidden = true
        }

        let app = getAppByName(name: result.appName)

        cell.iconImageView.image = UIImage(named: app?.icon ?? Settings.placeholderImageName)
        if let server = result.server {
            cell.serverLabel.text = LocalizedStrings.PreviousResults.server
            cell.serverValueLabel.text = server
            cell.serverLabel.isHidden = false
            cell.serverValueLabel.isHidden = false
        } else {
            cell.serverValueLabel.isHidden = true
            cell.serverLabel.isHidden = true
        }
        cell.carrierLabel.text = LocalizedStrings.PreviousResults.carrier
        cell.carrierValueLabel.text = result.carrier
        cell.carrierLabel.isHidden = false
        cell.carrierValueLabel.isHidden = false
        cell.ipVersionValueLabel.text = result.ipVersion
        cell.ipVersionLabel.isHidden = false

        let outputFormatter = DateFormatter()

        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        outputFormatter.doesRelativeDateFormatting = true

        cell.dateTextField.text = outputFormatter.string(from: result.date)
        if app?.isPortTest ?? false { // port test
            cell.appThroughputText.text = LocalizedStrings.App.portThroughput
            cell.nonAppThroughputText.text = LocalizedStrings.App.baselineThroughput
        } else { // normal test
            cell.appThroughputText.text = LocalizedStrings.PreviousResults.appThroughput
            cell.nonAppThroughputText.text = LocalizedStrings.PreviousResults.nonAppThroughput
        }

        cell.nonAppThroughputTextField.text = String(format: "%.1f " + LocalizedStrings.Generic.mbps, result.testAverageThroughput)
        cell.appThroughputTextField.text = String(format: "%.1f " + LocalizedStrings.Generic.mbps, result.originalAverageThroughput)

        let differentiation = result.differentiation ?? .inconclusive
        switch differentiation {
        case .noDifferentiation:
            cell.statusTextField.textColor = Settings.noDifferentiationColor
            cell.statusTextField.text = LocalizedStrings.Generic.noDifferentition
        case .inconclusive:
            cell.statusTextField.textColor = UIColor.orange
            cell.statusTextField.text = LocalizedStrings.Generic.inconclusive
        case .differentiation:
            cell.statusTextField.textColor = UIColor.red
            cell.statusTextField.text = LocalizedStrings.Generic.differentition
        }

        return cell
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
        saveResults()
    }

    // MARK: Private methods
    private func loadApps() -> [App] {
        if let blob = Helper.readJSONFile(filename: Settings.appFileName) {
            return Helper.jsonToApps(json: blob)
        } else {
            return [App]()
        }
    }

    private func saveResults() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(results, toFile: Result.ArchiveURL.path)
        if !isSuccessfulSave {
            print("Error saving results")
            print(results)
        }
    }

    private func getAppByName(name: String) -> App? {
        if let app = apps.first(where: { $0.name == name }) {
            return app
        } else {
            return nil
        }
    }

    private func beautify() {
        previousResultsTitle.title = LocalizedStrings.PreviousResults.previousResults
    }
}
