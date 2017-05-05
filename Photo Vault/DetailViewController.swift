//
//  DetailViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 3/30/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    // IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    
    // Properties
    var photo:UIImage?
    
    // Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photo {
            imageView.image = photo
            if photo.size.width > photo.size.height && self.view.frame.size.width < self.view.frame.size.height{
                let height = self.view.frame.size.width / (photo.size.width / photo.size.height)
                imageView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: height)
                self.preferredContentSize = CGSize(width: 0, height: height)
            }
            else if photo.size.width < photo.size.height && self.view.frame.size.width > self.view.frame.size.height{
                let width = self.view.frame.size.height / (photo.size.height / photo.size.width)
                imageView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: self.view.frame.size.height)
                self.preferredContentSize = CGSize(width: width, height: 0)
            }
            else{
                imageView.frame = self.view.frame
                self.preferredContentSize = self.view.frame.size
            }
            imageView.contentMode = .scaleAspectFill
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //TODO --> Implement this if you want
//    override var previewActionItems: [UIPreviewActionItem]{
//        
//        var mainView: PhotosCollectionViewController?
//        if var topController = UIApplication.shared.keyWindow?.rootViewController {
//            while let presentedViewController = topController.presentedViewController {
//                topController = presentedViewController
//                if presentedViewController is PhotosCollectionViewController{
//                    mainView = topController as? PhotosCollectionViewController
//                }
//            }
//        }
//        
//        let likeAction = UIPreviewAction(title: "Like", style: .default) { (action, viewController) -> Void in
//            print("You liked the photo")
//        }
//        
//        let deleteAction = UIPreviewAction(title: "Delete", style: .destructive) { (action, viewController) -> Void in
//            print("You deleted the photo")
//            mainView?.trashButtonClosure()
//        }
//        
//        return [likeAction, deleteAction]
//    }
}
