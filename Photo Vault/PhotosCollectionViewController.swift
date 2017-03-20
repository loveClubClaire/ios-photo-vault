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

private let reuseIdentifier = "photoCell"

extension UIImageView: DisplaceableView {}

struct Image {
    let thumbnail: UIImage
    let galleryItem: GalleryItem?
}

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var images = [Image]()
    var importedImages = [UIImage]()
    var archivePath: String?
    
    var selectedImages = [Int]()
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
        //TODO
        print("Hello everyone!")
        print(selectedImages)
    }
    
    // MARK: - Save and Load
    var imageFileNames = [String]()
    
    func saveImages(){
        //For all images being imported into the album...
        for anImage in importedImages{
            //Create a file name for the image
            //If file name exists for some reason, make a new one don't overwrite the file
            var title = String(arc4random()) + ".jpg"
            while imageFileNames.contains(title) {
                title = String(arc4random()) + ".jpg"
            }
            imageFileNames.append(title)
            //Convert the image to data (currently only supporting JPEG, may increase support as time goes on)
            let image = anImage
            let imagePath = imagesDirectoryPath.appending("/\(title)")
            let data = UIImageJPEGRepresentation(image, 1.0)
            //Save the image to disk
            let success = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
            if success == false {
                os_log("Failed to save image...", log: OSLog.default, type: .error)
            }
            //Resize the image to thumbnail size and quality (do this so we have small images to load into the collection view cells. Small images == less data to load from disk == smaller loading times)
            let thumbnail = resizeToThumbnail(image: image)
            let thumbnailPath = imagesDirectoryPath.appending("/\(title.components(separatedBy: ".")[0])thumbnail.jpg")
            let thumbnaildata = UIImageJPEGRepresentation(thumbnail, 1.0)
            //Save the thumbnail to disk
            let secondSuccess = FileManager.default.createFile(atPath: thumbnailPath, contents: thumbnaildata, attributes: nil)
            if secondSuccess == false {
                os_log("Failed to save thumbnail...", log: OSLog.default, type: .error)
            }
        }
        //Remove the contents of the imported images array and store the contents of the imageFileNames array to disk. If a version already exists, it is overridden.
        importedImages.removeAll()
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
        let itemsPerRow: CGFloat = 2
        var widthPerItem = floor(self.view.frame.width / itemsPerRow)
        if widthPerItem == self.view.frame.width / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        let size = CGSize(width: widthPerItem, height: widthPerItem)
        UIGraphicsBeginImageContextWithOptions(size,false,1.0)
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
    let galleryViewController = GalleryViewController(startIndex: indexPath.row, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: self, configuration: galleryConfiguration())
    self.presentImageGallery(galleryViewController)
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.builtIn),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(false),
            
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
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(true),
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
    
    @IBAction func test(_ sender: Any) {
        //importedImages.append(#imageLiteral(resourceName: "test2.JPG"))

        self.view.isUserInteractionEnabled = false
        self.navigationController?.view.isUserInteractionEnabled = false
        self.tabBarController?.view.isUserInteractionEnabled = false

        //Gray out the view
        let container: UIView = UIView()
        container.frame = self.view.frame
        container.center = self.view.center
        container.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        container.tag = 100
        //Create the progressbar box
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = self.view.center
        loadingView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        //Create the progress bar
        let progress = RPCircularProgress()
        progress.roundedCorners = false
        progress.thicknessRatio = 1
        
        progress.center = CGPoint.init(x: 40, y: 40)
        //Add the views to each other and to the main view
        loadingView.addSubview(progress)
        container.addSubview(loadingView)
        self.view.addSubview(container)
        
        
        for index in 0...100{
            progress.updateProgress(CGFloat(Double(index).multiplied(by: 0.01)), animated: true, initialDelay: 0)
        }
        
        let when = DispatchTime.now() + 3 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            if let viewWithTag = self.view.viewWithTag(100) {
                viewWithTag.removeFromSuperview()
            }
            self.view.isUserInteractionEnabled = true
            self.navigationController?.view.isUserInteractionEnabled = true
            self.tabBarController?.view.isUserInteractionEnabled = true
        }
        


        saveImages()
    }
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
