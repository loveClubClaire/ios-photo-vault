//
//  PhotosCollectionViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit
import os.log
import ImageViewer
import RPCircularProgress
import Photos
import AVFoundation

private let reuseIdentifier = "photoCell"

extension UIImageView: DisplaceableView {}

struct Image {
    let thumbnail: UIImage
    let galleryItem: GalleryItem?
}

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var images = [Image]()
    var archivePath: String?
    
    var selectedImages = [Int]()
    var selectedImagesAlbum = PHAssetCollection()
    let progress = RPCircularProgress()
    
    var albumName: String?
    var imagesDirectoryPath: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //Create a folder for storing this albums photos if one does not already exist.
        let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
        // Create a new path for the new images folder
        imagesDirectoryPath = documentsDirectory.appending("/Photos/\(albumName!)")
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: imagesDirectoryPath, isDirectory: &objcBool)
        // If the folder with the given path doesn't exist already, create it
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
        loadImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCollectionViewCell else{
            fatalError("Unexpected cell type")
        }
        // Configure the cell
        cell.imageView.image = images[indexPath.row].thumbnail
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    let itemsPerRow: CGFloat = 4
    let sectionInsets = UIEdgeInsets(top: 1.0, left: 0, bottom: 0, right: 0)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        var widthPerItem = floor(view.frame.width / itemsPerRow)
        if widthPerItem == view.frame.width / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //Calculates the minimum spacing the autolayout provides for width. This value is returned so the spacing is the same for the height as well as the width
        var widthPerItem = floor(view.frame.width / itemsPerRow)
        if widthPerItem == view.frame.width / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        return (view.frame.width - (widthPerItem * itemsPerRow)) / (itemsPerRow - 1)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch (segue.identifier ?? "") {
        case "addPhotos":
            guard let viewController = segue.destination.childViewControllers.first as? PhotoSelectorTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            viewController.photosCollectionViewController = self
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //If we are coming from the photo selector, we load the progress bar before the view appears so that its visible the moment the view is visable
        if selectedImages.isEmpty == false{
            //Disable user interaction with the view, navigation bar, or tab bar
            self.view.isUserInteractionEnabled = false
            self.navigationController?.view.isUserInteractionEnabled = false
            self.tabBarController?.view.isUserInteractionEnabled = false
            //Create a semi transucent gray view to place on the view to indicate that interaction is disabled
            let container: UIView = UIView()
            container.frame = self.view.frame
            container.center = self.view.center
            container.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            container.tag = 100
            //Create the progressbar box view
            let loadingView: UIView = UIView()
            loadingView.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
            loadingView.center = self.view.center
            loadingView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            loadingView.clipsToBounds = true
            loadingView.layer.cornerRadius = 10
            //Create the progress bar
            progress.roundedCorners = false
            progress.thicknessRatio = 1
            progress.center = CGPoint.init(x: 40, y: 40)
            //Add the views to each other and to the main view
            loadingView.addSubview(progress)
            container.addSubview(loadingView)
            self.view.addSubview(container)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //When the view does appear (coming from the photo selector) we save the new images as an async task
        if selectedImages.isEmpty == false{
            DispatchQueue.global().async {
                self.saveNewImages()
            }
        }
    }
    
    // MARK: - Save and Load
    var imageFileNames = [String]()
    
    func saveNewImages(){
        //Calculate the amount the progress bar increments for each photo saved
        let incrementValue = CGFloat.init(1.0 / Double(selectedImages.count))
        var progress = CGFloat(0.0)
        
        let photoAssets = PHAsset.fetchAssets(in: selectedImagesAlbum, options: nil) as! PHFetchResult<AnyObject>
        let imageManager = PHImageManager()
        //Itterate though the album we're importing from, and only take action on images which were selected by the user
        photoAssets.enumerateObjects({(object, count, stop) in
            if self.selectedImages.contains(count){
                if let asset = object as? PHAsset{
                    //We're getting the high quality version of each image
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .highQualityFormat
                    options.isSynchronous = true
                    //When we have an image
                    imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options, resultHandler: {
                        (image, info) -> Void in
                        //Create a file name for the image
                        //If file name exists for some reason, make a new one don't overwrite the file
                        var title = String(arc4random()) + ".jpg"
                        while self.imageFileNames.contains(title) {
                            title = String(arc4random()) + ".jpg"
                        }
                        self.imageFileNames.append(title)
                        //Convert the image to data (currently only supporting JPEG, may increase support as time goes on)
                        let image = image
                        let imagePath = self.imagesDirectoryPath.appending("/\(title)")
                        let data = UIImageJPEGRepresentation(image!, 1.0)
                        //Save the image to disk
                        let success = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
                        if success == false {
                            os_log("Failed to save image...", log: OSLog.default, type: .error)
                        }
                        //Resize the image to thumbnail size and quality (do this so we have small images to load into the collection view cells. Small images == less data to load from disk == smaller loading times)
                        let thumbnail = self.resizeToThumbnail(image: image!)
                        let thumbnailPath = self.imagesDirectoryPath.appending("/\(title.components(separatedBy: ".")[0])thumbnail.jpg")
                        let thumbnaildata = UIImageJPEGRepresentation(thumbnail, 1.0)
                        //Save the thumbnail to disk
                        let secondSuccess = FileManager.default.createFile(atPath: thumbnailPath, contents: thumbnaildata, attributes: nil)
                        if secondSuccess == false {
                            os_log("Failed to save thumbnail...", log: OSLog.default, type: .error)
                        }
                        
                        //Store a custom fetch image function in a variable
                        let myFetchImageBlock: FetchImageBlock = {
                            //When called, this function loads the selected full quality image into memory
                            let fetchedData = FileManager.default.contents(atPath: imagePath)
                            let fetchedImage = UIImage(data: fetchedData!)
                            $0(fetchedImage)
                        }
                        
                        let itemViewControllerBlock: ItemViewControllerBlock = { index, itemCount, fetchImageBlock, configuration, isInitialController in
                            return AnimatedViewController(index: index, itemCount: itemCount, fetchImageBlock: myFetchImageBlock, configuration: configuration, isInitialController: isInitialController)
                        }
                        //Create a new gallery item containing the two custom functions defined above.
                        let galleryItem = GalleryItem.custom(fetchImageBlock: myFetchImageBlock, itemViewControllerBlock: itemViewControllerBlock)
                        //Add the thumbnail images and it's corresponding galleryItem to our imageArray as a new Image object
                        self.images.append(Image.init(thumbnail: thumbnail, galleryItem: galleryItem))
                        
                        //Grab the main thread and update the progress bar. By launching saveNewImages as an async task, the main thread is not blocked. So when we go to grab it and update the UI, the UI will actually update.
                        DispatchQueue.main.sync {
                            progress = progress + incrementValue
                            self.progress.updateProgress(progress, animated: true, initialDelay: 0)
                            self.collectionView?.reloadData()
                        }
                    })
                }
            }
        })
        //When all the photos are loaded, grab the main thread and dismiss the progress bar views
        DispatchQueue.main.sync {
            if let viewWithTag = self.view.viewWithTag(100) {
                //Delay removing the progress bar views for a 1/4 of a second. So the user see's the complete progress bar long enough to regester that the task has been completed.
                let when = DispatchTime.now() + 0.25
                DispatchQueue.main.asyncAfter(deadline: when) {
                    viewWithTag.removeFromSuperview()
                    //Set the progress bar to zero so it's not already filled the next time it's called 
                    self.progress.updateProgress(0.0)
                }
            }
                
            //Reenable user interaction
            self.view.isUserInteractionEnabled = true
            self.navigationController?.view.isUserInteractionEnabled = true
            self.tabBarController?.view.isUserInteractionEnabled = true
    }
        //Save the image file names
        NSKeyedArchiver.archiveRootObject(imageFileNames, toFile: imagesDirectoryPath.appending("/pictures"))
    }

    func loadImages(){
        //Load the array of image file names
        imageFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/pictures")) as? [String]) ?? []
        //For every imageFileName..
        for imagePath in imageFileNames{
            //Generate a path to the thumbnail image and load it from disk into memory
            let thumbnailPath = imagePath.components(separatedBy: ".")[0] + "thumbnail.jpg"
            let data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(thumbnailPath)"))
            let image = UIImage(data: data!)
            //Store a custom fetch image function in a variable
            let myFetchImageBlock: FetchImageBlock = {
                //When called, this function loads the selected full quality image into memory
                let fetchedData = FileManager.default.contents(atPath: self.imagesDirectoryPath.appending("/\(imagePath)"))
                let fetchedImage = UIImage(data: fetchedData!)
                $0(fetchedImage)
            }
            
            let itemViewControllerBlock: ItemViewControllerBlock = { index, itemCount, fetchImageBlock, configuration, isInitialController in
                return AnimatedViewController(index: index, itemCount: itemCount, fetchImageBlock: myFetchImageBlock, configuration: configuration, isInitialController: isInitialController)
           }
            //Create a new gallery item containing the two custom functions defined above.
            let galleryItem = GalleryItem.custom(fetchImageBlock: myFetchImageBlock, itemViewControllerBlock: itemViewControllerBlock)
            //Add the thumbnail images and it's corresponding galleryItem to our imageArray as a new Image object
            images.append(Image.init(thumbnail: image!, galleryItem: galleryItem))
        }
    }
    
    

    
    func resizeToThumbnail(image: UIImage) -> UIImage{
        //Make the image size the exact size of the cell. Do it for speed. "Gotta go fast"
        let itemsPerRow: CGFloat = 1
        var widthPerItem = floor(self.view.frame.width / itemsPerRow)
        if widthPerItem == self.view.frame.width / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        
        var factor = CGFloat(0.0)
        if image.size.width > image.size.height{
            factor = image.size.width.divided(by: widthPerItem)
        }
        if image.size.width <= image.size.height{
            factor = image.size.height.divided(by: widthPerItem)
        }
        
        let size = CGSize(width: image.size.width.divided(by: factor), height: image.size.height.divided(by: factor))

        
        UIGraphicsBeginImageContextWithOptions(size,false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return resizedImage
        }
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let headerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: ((self.navigationController?.navigationBar.frame.height)! + UIApplication.shared.statusBarFrame.height))
        let footerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: (self.tabBarController?.tabBar.frame.height)!)
        let headerView = UIView.init(frame: headerFrame)
        let footerView = UIView.init(frame: footerFrame)
        
       
        headerView.backgroundColor = UIColor.white
        footerView.backgroundColor = UIColor.white
        
        
            
        let galleryViewController = GalleryViewController(startIndex: indexPath.row, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: self, configuration: galleryConfiguration())
        
        galleryViewController.headerView = headerView
        galleryViewController.footerView = footerView

        galleryViewController.photoSingleTap = {
            print("Photo Tapped")
            if self.showStatusBar == true{self.showStatusBar = false}
            else {self.showStatusBar = true}
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        galleryViewController.swipedToDismissCompletion = {self.showStatusBar = true}
        showStatusBar = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.presentImageGallery(galleryViewController)
    }
    
    var showStatusBar = true
    override var prefersStatusBarHidden: Bool {
        if showStatusBar{return false}
        return true
    }

    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            GalleryConfigurationItem.footerViewLayout(.center(0)),
            GalleryConfigurationItem.headerViewLayout(.center(0)),
            
            GalleryConfigurationItem.thumbnailsButtonMode(.none),
            GalleryConfigurationItem.deleteButtonMode(.none),
            GalleryConfigurationItem.closeButtonMode(.none),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(true),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.0),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(false),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50)
        ]
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
}
// MARK: - ImageView Extensions
//Done as extensions because that's how this works I guess
extension PhotosCollectionViewController: GalleryDisplacedViewsDataSource {
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        if index < images.count {
            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: IndexPath.init(row: index, section: 0)) as? PhotoCollectionViewCell else{
                fatalError("Unexpected cell type")
            }
            return cell.imageView
        }
        else{
            return nil
        }
    }
}

extension PhotosCollectionViewController: GalleryItemsDataSource{
    func itemCount() -> Int {
        return images.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return images[index].galleryItem!
    }
}


// Some external custom UIImageView we want to show in the gallery
class FLSomeAnimatedImage: UIImageView {}
// Extend ImageBaseController so we get all the functionality for free
class AnimatedViewController: ItemBaseController<FLSomeAnimatedImage> {}
