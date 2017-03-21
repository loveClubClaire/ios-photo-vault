//
//  UINavigationBar+Extension.swift
//  
//
//  Created by Zachary Whitten on 3/21/17.
//
//  This extension is used for maintaining a navagationBar's height when the status bar is hidden. Becuase the status bar is it's own frame, when it disapears the navagationBar jumps up X number of pixals. This just grows the navagationBar's height to make up the difference of the missing status bar, and to shrink back when the status bar returns

import UIKit
import Foundation

var defaultHeight:CGFloat? = nil
var statusBarHeight:CGFloat? = nil

extension UINavigationBar{
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
