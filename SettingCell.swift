//
//  SettingCell.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/4/27.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit

class SettingCell: UITableViewCell {

    @IBOutlet weak var m_label: UILabel!
    @IBOutlet weak var m_switch: UISwitch!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
