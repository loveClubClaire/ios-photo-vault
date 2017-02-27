//
//  PhotoSelectorCollectionViewCell.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/27/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit

class PhotoSelectorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
        }
    }
}
