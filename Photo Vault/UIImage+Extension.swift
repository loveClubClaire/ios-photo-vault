//
//  UIImage+Extension.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 3/22/17.
//  Copyright © 2017 16^2. All rights reserved.
//
//
//  UIImage+imageFromSystemBarButton.swift
//  http://stackoverflow.com/a/40566599/3594256
//  http://stackoverflow.com/a/41688097/3594256

import UIKit

extension UIImage{
    
    class func imageFromSystemBarButton(_ systemItem: UIBarButtonSystemItem)-> UIImage {
        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        return imageFromBarButtonItem(tempItem)
    }
    
    private class func imageFromBarButtonItem(_ barButton: UIBarButtonItem)-> UIImage{
        // add to toolbar and render it
        UIToolbar().setItems([barButton], animated: false)
        
        // got image from real uibutton
        let itemView = barButton.value(forKey: "view") as! UIView
        
        for view in itemView.subviews {
            if view is UIButton {
                let button = view as! UIButton
                let image = button.imageView!.image!
                return image.tint(with: button.tintColor)
            }
        }
        return UIImage()
    }
    
    func tint(with color: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.set()
        
        image.draw(in: CGRect(origin: .zero, size: size))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
