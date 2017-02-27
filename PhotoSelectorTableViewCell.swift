//
//  PhotoSelectorTableViewCell.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/26/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit

class PhotoSelectorTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var albumName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
