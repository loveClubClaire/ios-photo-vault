//
//  PhotoCollectionViewCell.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
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
