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
    @IBOutlet weak var checkMark: SSCheckMark!
    
    override var isSelected: Bool {
        didSet {
            checkMark.backgroundColor = UIColor.clear
            if isSelected == true{
                checkMark.checked = true
                checkMark.isHidden = false
            }
            else{
                checkMark.checked = false
                checkMark.isHidden = true
            }
        }
    }
}
