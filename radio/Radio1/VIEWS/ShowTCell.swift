//
//  ShowTCell.swift
//  Radio1
//
//  Created by ismmajl on 12/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import UIKit

class ShowTCell: UITableViewCell {

    @IBOutlet weak var sImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    var show: Show! {
        didSet {
            setValues()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    func setValues() {
        nameLabel.text = show.title
        descLabel.text = show.desc
        timeLabel.text = show.startTime + " - " + show.endTime
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
