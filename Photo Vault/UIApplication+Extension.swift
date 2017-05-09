//
//  UIApplication+Extension.swift
//  Photo Vault
//
//  Created by jcady
//  http://stackoverflow.com/a/34666180

import UIKit

extension UIApplication
{
    class func dismissOpenAlerts(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController)
    {
        //If it's an alert, dismiss it
        if let alertController = base as? UIAlertController
        {
            alertController.dismiss(animated: false, completion: nil)
        }
        
        //Check all children
        if base != nil
        {
            for controller in base!.childViewControllers
            {
                if let alertController = controller as? UIAlertController
                {
                    alertController.dismiss(animated: false, completion: nil)
                }
            }
        }
        
        //Traverse the view controller tree
        if let nav = base as? UINavigationController
        {
            dismissOpenAlerts(base: nav.visibleViewController)
        }
        else if let tab = base as? UITabBarController, let selected = tab.selectedViewController
        {
            dismissOpenAlerts(base: selected)
        }
        else if let presented = base?.presentedViewController
        {
            dismissOpenAlerts(base: presented)
        }
    }
}
