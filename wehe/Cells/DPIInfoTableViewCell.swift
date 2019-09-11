//
//  DPIInfoTableViewCell.swift
//  wehe
//
//  Created by Ivan Chen on 4/11/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit

class DPIInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var betaLabel: UILabel!

    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var startButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
    }

    func waiting() {
        resultTextView.isHidden = true
        startButton.isHidden = true
        resetButton.isHidden = true
        spinner.isHidden = false
        spinner.startAnimating()
    }

    func haveResult(haveConnection: Bool) {
        resultTextView.isHidden = false
        startButton.isHidden = false
        spinner.isHidden = true
        spinner.stopAnimating()
        if haveConnection {
            startButton.setTitle(LocalizedStrings.MoreInfo.DPIInfoCell.startDPI, for: .normal)
            resetButton.isHidden = false
        } else {
            startButton.setTitle(LocalizedStrings.Generic.retry, for: .normal)
            resetButton.isHidden = true
        }
    }

    private func beautify() {
        resultTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        infoTextView.text = LocalizedStrings.MoreInfo.DPIInfoCell.infoText
        titleLabel.text = LocalizedStrings.MoreInfo.DPIInfoCell.title
        betaLabel.text = LocalizedStrings.MoreInfo.DPIInfoCell.beta
        resetButton.setTitle(LocalizedStrings.MoreInfo.DPIInfoCell.reset, for: .normal)
        startButton.setTitle(LocalizedStrings.MoreInfo.DPIInfoCell.startDPI, for: .normal)
    }
}
