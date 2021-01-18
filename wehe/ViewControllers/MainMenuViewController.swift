//
//  MainViewController.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/8/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import SideMenu

class MainMenuViewController: UIViewController {

    @IBOutlet weak var aboutWeheButton: UIButton!
    @IBOutlet weak var runTestButton: UIButton!
    @IBOutlet weak var portTestButton: UIButton!
    @IBOutlet weak var previousResultsButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var functionalityButton: UIButton!
    @IBOutlet weak var viewOnlineDashboardButton: UIButton!
    var portTests = false

    // MARK: Properties
    var settings: Settings?

    override func viewDidLoad() {
        super.viewDidLoad()
        settings = Globals.settings
        beautify()
        if let leftMenuNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController {
            leftMenuNavigationController.pushStyle = .preserve
            SideMenuManager.default.leftMenuNavigationController = leftMenuNavigationController
        } else {
//            Deprecated
//            SideMenuManager.default.menuPushStyle = .preserve
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let target = segue.destination
        if let appCollection = target as? AppCollectionViewController {
            if portTests {
                appCollection.portTests = true
            }
            portTests = false
        }
    }

    // MARK: Private methods

    private func beautify() {
        if settings!.firstTimeLaunch {
            settings!.firstTimeLaunch = false
            aboutWeheButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: (aboutWeheButton.titleLabel?.font.pointSize)!)
            aboutWeheButton.titleLabel?.layer.shadowColor = UIColor.blue.cgColor
            aboutWeheButton.titleLabel?.layer.shadowRadius = 4.0
            aboutWeheButton.titleLabel?.layer.shadowOpacity = 0.9
            aboutWeheButton.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 0)
            aboutWeheButton.titleLabel?.layer.masksToBounds = false
        }
        aboutWeheButton.setTitle(LocalizedStrings.aboutWehe.title, for: .normal)
        runTestButton.setTitle(LocalizedStrings.MainMenu.runTests, for: .normal)
        portTestButton.setTitle(LocalizedStrings.MainMenu.runPortTests, for: .normal)
        previousResultsButton.setTitle(LocalizedStrings.MainMenu.previousResults, for: .normal)
        settingsButton.setTitle(LocalizedStrings.MainMenu.settings, for: .normal)
        functionalityButton.setTitle(LocalizedStrings.MainMenu.functionality, for: .normal)
        viewOnlineDashboardButton.setTitle(LocalizedStrings.MainMenu.viewOnlineDashboard, for: .normal)
    }

    @IBAction func portTestTap(_ sender: Any) {
        portTests = true
        performSegue(withIdentifier: "portTest", sender: self)
    }
}
