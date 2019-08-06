//
//  CanvasDetailTableViewCell.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/12/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit

class CanvasDetailTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var canvasTitleLabel: UILabel!
    @IBOutlet weak var lastEditLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
