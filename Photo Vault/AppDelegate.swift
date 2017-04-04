//
//  AppDelegate.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit
import Photos

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //If photo library authorization has not been determined, attempt to access the photo library on app launch to trigger the user notification
        //Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        //if access has not been determined.
        if (status == PHAuthorizationStatus.notDetermined) {
            _ = [PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: PHFetchOptions())]
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        application.ignoreSnapshotOnNextApplicationLaunch()
        
        let colorView = UIView(frame: (self.window?.frame)!)
        colorView.tag = 9999
        colorView.backgroundColor = UIColor.black
        self.window?.addSubview(colorView)
        self.window?.bringSubview(toFront: colorView)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let colorView = self.window?.viewWithTag(9999)
        colorView?.removeFromSuperview()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

