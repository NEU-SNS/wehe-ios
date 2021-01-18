//
//  ResultTableViewCell.swift
//  wehe
//
//  Created by Kirill Voloshin on 11/2/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SafariServices

class ResultTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var statusTextField: UILabel!
    @IBOutlet weak var dateTextField: UILabel!
    @IBOutlet weak var appThroughputTextField: UILabel!
    @IBOutlet weak var nonAppThroughputTextField: UILabel!
    @IBOutlet weak var appThroughputText: UILabel!
    @IBOutlet weak var nonAppThroughputText: UILabel!
    @IBOutlet weak var ipVersionValueLabel: UILabel!
    @IBOutlet weak var ipVersionLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var serverValueLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var arcepLogo: UIImageView!
    @IBOutlet weak var carrierLabel: UILabel!
    @IBOutlet weak var carrierValueLabel: UILabel!
    weak var cellDelegate: AlertCell?
    var result: Result?

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func beautify() {
        reportButton.setTitle(LocalizedStrings.ReplayView.alertArcep, for: .normal)
    }
    private func alert(title: String, message: String) {
        cellDelegate?.showAlert(title: title, message: message)
    }

    @IBAction func reportButtonPressed(_ sender: Any) {
        showArcepPage()
    }

    func showArcepPage() {
        if let url = URL(string: "https://jalerte.arcep.fr/jalerte/?2") {
            UIApplication.shared.open(url)
        }
    }
}
