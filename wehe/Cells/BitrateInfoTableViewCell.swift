//
//  BitrateInfoTableViewCell.swift
//  wehe
//
//  Created by Ivan Chen on 4/11/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit

class BitrateInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
    }

    private func beautify() {
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        titleLabel.text = LocalizedStrings.MoreInfo.BitrateInfoCell.title
    }

}
