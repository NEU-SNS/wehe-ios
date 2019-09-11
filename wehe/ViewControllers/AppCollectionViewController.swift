//
//  AppCollectionViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/17/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit
import SwiftyJSON
import NotificationBannerSwift
import CoreLocation
import Alamofire
import StoreKit

class AppCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var runTestButton: UIButton!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var totalSizeNameLabel: UILabel!
    @IBOutlet weak var totalSizeLabel: UILabel!

    // MARK: Properties
    var apps = [App]()

    let defaults = UserDefaults.standard
    let locationManager = CLLocationManager()
    var settings: Settings?

    var sessionManager: SessionManager?

    let testsPerReplay: Float = 2

    override func viewDidLoad() {
        super.viewDidLoad()

        settings = Globals.settings

        // main-menu set-up
        let locationAuthorization = CLLocationManager.authorizationStatus()
        let locationServiceEnabled = CLLocationManager.locationServicesEnabled()
        if settings!.sendStats && locationServiceEnabled && locationAuthorization != .denied {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            if locationAuthorization != .authorizedWhenInUse {
                locationManager.requestWhenInUseAuthorization()
            }
        }

        loadDefaultSettings()

        if hasResults() && !settings!.askedToRate {
            settings!.askedToRate = true
            askToRate()
        }

        // -------
        beautify()
        loadAppsFile()
        initialSize()
        if settings!.consent {
            showWiFiWarning()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()

        if !settings!.consent {
            performSegue(withIdentifier: "showConsent", sender: nil)
        } else {
            if settings!.firstTimeLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.performSegue(withIdentifier: "showSideMenu", sender: nil)
//                    self.settings!.firstTimeLaunch = false
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roundButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // for a bug in iOS 11.2 where the button will be disabled
//        runTestButton.isEnabled = false
//        runTestButton.isEnabled = true
    }

    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return apps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppCollectionViewCell", for: indexPath) as? AppCollectionViewCell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AppCollectionViewCell", for: indexPath)
        }

        let app = apps[indexPath.row]
        cell.iconImageView.image = UIImage(named: app.icon)
        cell.app = app
        cell.selectionSwitch.addTarget(self, action: #selector(switchToggled), for: UIControl.Event.valueChanged)

        return cell
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ReplayViewController {
            var selectedApps = [App]()

            for app in apps where app.isSelected {
                if let copy = app.copy() as? App {
                    selectedApps.append(copy)
                }
            }

            destination.settings = settings
            destination.apps = selectedApps
        }
    }

    // MARK: Segue
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        var appsSelected = false
//        if let cells = self.tableView.visibleCells as? [AppTableViewCell] {
//            for cell in cells where cell.selectSwitch.isOn {
//                appsSelected = true
//            }
//
//            return appsSelected
//        }
//        return appsSelected
//    }

    // MARK: Actions

    @objc func switchToggled(switch: UISwitch) {
        updateSize()
        updateRunButton()
    }

    @IBAction func back(_ sender: UIBarButtonItem) {
//        dismiss(animated: true, completion: nil)
    }

    // MARK: Private methods
    private func loadAppsFile() {
        if let blob = Helper.readJSONFile(filename: Settings.appFileName) {
            addApps(json: blob)
        } else {
            let warningMessage = "There was an error reading the app list file"

            let alertController = UIAlertController(title: "Error", message: warningMessage, preferredStyle: UIAlertController.Style.alert)

            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {(_) -> Void in
                self.dismiss(animated: true, completion: nil)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func addApps(json: JSON) {
        guard json["apps"] != JSON.null else {
            print("apps key not found in JSON")
            return
        }

        apps = Helper.jsonToApps(json: json)
        for app in apps {
            app.isSelected = true
        }
    }

    private func showWiFiWarning() {
        if !Helper.isOnWiFi() {
            return
        }

        let carrier = Helper.getCarrier() ?? LocalizedStrings.AppTable.defaultMobileCareer
        let subtitle = String(format: LocalizedStrings.AppTable.wifiWarning, carrier)

        let banner = StatusBarNotificationBanner(title: subtitle, style: .warning)

        banner.show()
    }

    private func beautify() {
//        backButton.title = LocalizedStrings.Generic.back
        runTestButton.setTitle(LocalizedStrings.AppTable.runTests, for: .normal)
        totalSizeNameLabel.text = String(format: "%@:", LocalizedStrings.AppTable.size)
    }

    // Turn the run button into a round boy https://twitter.com/round_boys
    private func roundButton() {
        runTestButton.layer.cornerRadius = runTestButton.bounds.size.width * 0.5
        runTestButton.clipsToBounds = true
        runTestButton.layer.borderWidth = 2
        runTestButton.layer.borderColor = Helper.colorFromRGB(r: 54, g: 95, b: 133).cgColor
    }

    private func initialSize() {
        var totalSize: Float = 0
        for app in apps {
            totalSize += (Float(app.size ?? "0") ?? 0) * testsPerReplay
        }

        totalSizeLabel.text = String(format: "%.1f MB", totalSize)
    }

    private func updateSize() {
        var totalSize: Float = 0

        for app in apps where app.isSelected {
            totalSize += (Float(app.size ?? "0") ?? 0) * testsPerReplay
        }

        totalSizeLabel.text = String(format: "%.1f MB", totalSize)
    }

    private func updateRunButton() {
        var anySelected = false
        for app in apps where app.isSelected {
            anySelected = true
            break
        }
        runTestButton.isEnabled = anySelected
    }

    private func hasResults() -> Bool {
        let results = Helper.loadResults()
        return results.count != 0
    }

    private func askToRate() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            let alertController = UIAlertController(title: LocalizedStrings.rateAlert.title, message: LocalizedStrings.rateAlert.message, preferredStyle: UIAlertController.Style.alert)

            alertController.addAction(UIAlertAction(title: LocalizedStrings.rateAlert.no, style: UIAlertAction.Style.default, handler: nil))

            alertController.addAction(UIAlertAction(title: LocalizedStrings.rateAlert.yes, style: UIAlertAction.Style.default, handler: {(_) -> Void in
                self.rateApp(appId: Settings.appID)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func rateApp(appId: String) {
        var urlString = ""
        if Helper.isFrenchLocale() {
            urlString = "https://itunes.apple.com/fr/app/mobile-legislate/id" + appId + "?mt=8"
        } else {
            urlString = "https://itunes.apple.com/us/app/mobile-legislate/id" + appId + "?mt=8"
        }
        guard let url = URL(string: urlString) else {
            return
        }
        guard #available(iOS 10, *) else {
            print("opening url")
            UIApplication.shared.openURL(url)
            return
        }
    }

    // Main-menu set-up
    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            settings!.latitude = String(location.coordinate.latitude)
            settings!.longitude = String(location.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    private func loadDefaultSettings() {
        let parameters: Parameters = ["userID": settings!.randomID, "command": "defaultSetting"]
        let url = Helper.makeURL(ip: settings!.serverIP, port: String(settings!.resultsPort), api: "Results", https: false)
        sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default, delegate: SessionManager.default.delegate, serverTrustPolicyManager: Helper.serverTrustPoliceManager(server: settings!.serverIP))

        sessionManager!.request(url, parameters: parameters).responseJSON { response in
            if let result = response.result.value {
                let json = JSON(result)
                if json != JSON.null && json["success"].bool! {
                    if let ks2Threshold = json["ks2Threshold"].string {
                        if let ks2ThresholdDouble = Double(ks2Threshold) {
                            self.settings!.defaultpValueThreshold = ks2ThresholdDouble
                        }
                    }

                    if let ks2Ratio = json["ks2Ratio"].string {
                        if let ks2RatioDouble = Double(ks2Ratio) {
                            self.settings!.defaultKS2Ratio = ks2RatioDouble
                        }
                    }

                    if let areaThreshold = json["areaThreshold"].string {
                        if let areaThresholdDouble = Double(areaThreshold) {
                            self.settings!.defaultAreaThreshold = areaThresholdDouble
                        }
                    }
                }
            }
        }
    }

}
