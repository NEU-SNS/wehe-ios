//
//  AppCollectionViewCell.swift
//  wehe
//
//  Created by Work on 9/17/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import UIKit

class AppCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var selectionSwitch: UISwitch!

    var app: App?

    override func awakeFromNib() {
        super.awakeFromNib()
        beautify()
//        selectSwitch.isOn = false
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

    private func beautify() {
//        timeLabel.text = LocalizedStrings.AppTable.time
//        sizeLabel.text = LocalizedStrings.AppTable.size
    }
    @IBAction func switchFlipped(_ sender: Any) {
        app?.isSelected = selectionSwitch.isOn
    }

}
