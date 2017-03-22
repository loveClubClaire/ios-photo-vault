//
//  CustomNavigationBar.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 3/21/17.
//  Copyright © 2017 16^2. All rights reserved.
//  This subclass is used for maintaining a navagationBar's height when the status bar is hidden. Becuase the status bar is it's own frame, when it disapears the navagationBar jumps up X number of pixals. This just grows the navagationBar's height to make up the difference of the missing status bar, and to shrink back when the status bar returns

import UIKit
import Foundation

class CustomNavigationBar: UINavigationBar {
    var defaultHeight:CGFloat? = nil
    var statusBarHeight:CGFloat? = nil
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        if defaultHeight == nil{defaultHeight = self.frame.height}
        if statusBarHeight == nil{statusBarHeight = UIApplication.shared.statusBarFrame.height}
        if UIApplication.shared.isStatusBarHidden{
            return CGSize(width: UIScreen.main.bounds.width, height: defaultHeight! + statusBarHeight!)
        }
        else{
            return CGSize(width: UIScreen.main.bounds.width, height: defaultHeight!)
        }
    }

}
