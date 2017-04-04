//
//  PhotosCollectionViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//
//  https://the-nerd.be/2015/10/06/3d-touch-peek-and-pop-tutorial/

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

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate, UIViewControllerPreviewingDelegate {
    
    var images = [Image]()
    var archivePath: String?
    
    var selectedImages = [Int]()
    var selectedImagesAlbum = PHAssetCollection()
    let progress = RPCircularProgress()
    
    var albumName: String?
    var imagesDirectoryPath: String!
    
    let numJunkBytes = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //If the device has a 3D touch screen, register our view controller for peeking and popping
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self as UIViewControllerPreviewingDelegate, sourceView: view)
        }
        //Create a folder for storing this albums photos if one does not already exist.
        let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
        // Create a new path for the new images folder
        imagesDirectoryPath = documentsDirectory.appending("/Photos")
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
        //Set the navigation bar title
        self.navigationItem.title = albumName
        //Allow multiple images to be selected
        self.collectionView?.allowsMultipleSelection = true
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
    let pointWidth = UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        var widthPerItem = floor(pointWidth / itemsPerRow)
        if widthPerItem == pointWidth / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //Calculates the minimum spacing the autolayout provides for width. This value is returned so the spacing is the same for the height as well as the width
        var widthPerItem = floor(pointWidth / itemsPerRow)
        if widthPerItem == pointWidth / itemsPerRow {
            widthPerItem = widthPerItem - 0.5
        }
        return (pointWidth - (widthPerItem * itemsPerRow)) / (itemsPerRow - 1)
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
                        var data = UIImageJPEGRepresentation(image!, 1.0)
                        data?.addJunkHeader()
                        //Save the image to disk
                        let success = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
                        if success == false {
                            os_log("Failed to save image...", log: OSLog.default, type: .error)
                        }
                        //Resize the image to thumbnail size and quality (do this so we have small images to load into the collection view cells. Small images == less data to load from disk == smaller loading times)
                        let thumbnail = self.resizeToThumbnail(image: image!)
                        let thumbnailPath = self.imagesDirectoryPath.appending("/\(title.components(separatedBy: ".")[0])thumbnail.jpg")
                        var thumbnaildata = UIImageJPEGRepresentation(thumbnail, 1.0)
                        thumbnaildata?.addJunkHeader()
                        //Save the thumbnail to disk
                        let secondSuccess = FileManager.default.createFile(atPath: thumbnailPath, contents: thumbnaildata, attributes: nil)
                        if secondSuccess == false {
                            os_log("Failed to save thumbnail...", log: OSLog.default, type: .error)
                        }
                        
                        //Store a custom fetch image function in a variable
                        let myFetchImageBlock: FetchImageBlock = {
                            //When called, this function loads the selected full quality image into memory
                            var fetchedData = FileManager.default.contents(atPath: imagePath)
                            fetchedData?.removeJunkHeader()
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
        //Empty the selectedImages array 
        selectedImages.removeAll()
        //Save the image file names
        NSKeyedArchiver.archiveRootObject(imageFileNames, toFile: imagesDirectoryPath.appending("/\(albumName!)_albumPictures"))
    }

    func loadImages(){
        //Load the array of image file names
        imageFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/\(albumName!)_albumPictures")) as? [String]) ?? []
        //For every imageFileName..
        for imagePath in imageFileNames{
            //Generate a path to the thumbnail image and load it from disk into memory
            let thumbnailPath = imagePath.components(separatedBy: ".")[0] + "thumbnail.jpg"
            var data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(thumbnailPath)"))
            data?.removeJunkHeader()
            let image = UIImage(data: data!)
            //Store a custom fetch image function in a variable
            let myFetchImageBlock: FetchImageBlock = {
                //When called, this function loads the selected full quality image into memory
                var fetchedData = FileManager.default.contents(atPath: self.imagesDirectoryPath.appending("/\(imagePath)"))
                fetchedData?.removeJunkHeader()
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
    
    func deleteImages(_ selectedImages: IndexSet){
        var selectedElements = [String]()
        for index in selectedImages{
            selectedElements.append(imageFileNames[index])
        }
        
        for imagePath in selectedElements {
            let thumbnailPath = imagePath.components(separatedBy: ".")[0] + "thumbnail.jpg"
            do {
                try FileManager.default.removeItem(atPath: imagesDirectoryPath.appending("/\(thumbnailPath)"))
                try FileManager.default.removeItem(atPath: imagesDirectoryPath.appending("/\(imagePath)"))
            }
            catch{
                os_log("Failed to delete image & thumbnail...", log: OSLog.default, type: .error)
            }
        }
        let remainingFileNames = imageFileNames.filter{!selectedElements.contains($0)}
        imageFileNames = remainingFileNames
        NSKeyedArchiver.archiveRootObject(remainingFileNames, toFile: imagesDirectoryPath.appending("/\(albumName!)_albumPictures"))
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
    let docController = UIDocumentInteractionController()
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Check to see if we're tapping an image or selecting images. If we're selecting images, this function does nothing
        if isSelecting == false{
        //Get all the selected items and unselect them
            //This function is called when an item is selected. But in this instance, the user is tapping an image to display it fully, not selecting images. By deselecting the image immediately after it's selected, the cell's UI does not update to indicate it's selected. Nor are multiple cells already selected when a user goes to select images
        let selectedItems = self.collectionView?.indexPathsForSelectedItems
        for indexPath in selectedItems!{
            self.collectionView?.deselectItem(at: indexPath, animated: false)
        }
        //Get the portrait width of the iOS device
        let pointWidth = UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
        //Define the colorspace and the color for the header and footer border
        let space : CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let color : CGColor = CGColor(colorSpace: space, components: [0.0, 0.0, 0.0, 0.3])!
        //Create the header and footer frames and views. The header and footer get their height from the navigation bar and the tab bar respectively. The header height is actually the navigation bar height plus the height of the status bar frame because if that's not accounted for, the view will just overlap the status bar.
        let headerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: ((self.navigationController?.navigationBar.frame.height)! + UIApplication.shared.statusBarFrame.height))
        let footerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 49)
        let headerView = UIView.init(frame: headerFrame)
        let footerView = UIView.init(frame: footerFrame)
        //What we do next is set the header views color, create a white view, and a border layer. Layering these three objects on top of each other give us the same appearance as a standard iOS navigation bar or tab bar. We do the same thing for the footer. We use the values we use because that's apparently what Apple uses. See http://stackoverflow.com/a/30154915/3594256 for more detail
        //Set the header view's color
        headerView.backgroundColor = UIColor.white
        headerView.alpha = 0.85
        headerView.isOpaque = false
        //Create the headers white view
        let whiteHeaderFrame = UIView.init(frame: headerFrame)
        whiteHeaderFrame.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        whiteHeaderFrame.isOpaque = false
        whiteHeaderFrame.autoresizingMask = [.flexibleWidth]
        //Create the headers border
        let headerBorder = CALayer()
        headerBorder.backgroundColor = color
        headerBorder.frame = CGRect(x: 0, y: headerFrame.height - 0.25, width: pointWidth, height: 0.25)
        //Add the border to the white frame and add the white frame to the header
        whiteHeaderFrame.layer.addSublayer(headerBorder)
        headerView.addSubview(whiteHeaderFrame)
        //Set the footers color
        footerView.backgroundColor = UIColor.white
        footerView.alpha = 0.85
        footerView.isOpaque = false
        //Create the footers white view
        let whiteFooterFrame = UIView.init(frame: footerFrame)
        whiteFooterFrame.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        whiteFooterFrame.isOpaque = false
        whiteFooterFrame.autoresizingMask = [.flexibleWidth]
        //Create the footers border
        let footerBorder = CALayer()
        footerBorder.backgroundColor = color
        footerBorder.frame = CGRect(x: 0, y: 0, width: pointWidth, height: 0.25)
        //Add the border to the white frame and add the white frame to the footer
        whiteFooterFrame.layer.addSublayer(footerBorder)
        footerView.addSubview(whiteFooterFrame)
        //The next step is to add buttons and labels to the header and footer. In the case of the buttons, we create a button, give it an image, set the size of it's frame, set it's origin, and then add it to the headerView or the footerView
        //For the countLabel, we define only the height of the status bar, the stringTemplate, and a new UIlabel object. We add the empty label to the header view. We modify this empty label in a later completion block.
        //We define the status bar height here because the status bar is active and it gives us a non zero value. The completion block fires when the status bar is disabled, even though the label is shown when the status bar is enabled. Getting the status bar height here allows the label to appear in the expected position when visible.
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let stringTemplate = "%d of %d"
        let countLabel = UILabel()
        countLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        headerView.addSubview(countLabel)
        //Here we define the back button, give it an image, set it's frame size, set it's origin, and then add it to the headerView. The origin's Y value centers the back button in the header. (Keep in mind the header frame INCLUDES the size of the status bar, so it's not the TRUE center of the frame, but the center of the header sans status bar)
        let backButton = CustomUIButton(type: .custom)
        backButton.setImage(#imageLiteral(resourceName: "BackArrow.png"), for: .normal)
        backButton.frame.size = CGSize(width: 13, height: 21)
        backButton.frame.origin = CGPoint(x: 12, y: ((headerView.frame.height - backButton.frame.size.height)/2 + (UIApplication.shared.statusBarFrame.height / 2)))
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        headerView.addSubview(backButton)
        //Here we define the export image button. The set image comes from the .action Bar Button Item. The frame is set to the size of this image and then it's given an origin which centers the button's Y position in the footer. Then the button is added to the footer.
        let exportButton = CustomUIButton(type: .custom)
        exportButton.setImage(UIImage.imageFromSystemBarButton(.action), for: .normal)
        exportButton.sizeToFit()
        exportButton.frame.origin = CGPoint(x: 20.0, y: ((footerFrame.height - exportButton.frame.height) / 2))
        exportButton.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        footerView.addSubview(exportButton)
        //Creating the trash button and adding it to the footer view
        let trashButton = CustomUIButton(type: .custom)
        trashButton.setImage(UIImage.imageFromSystemBarButton(.trash), for: .normal)
        trashButton.sizeToFit()
        trashButton.frame.origin = CGPoint(x: footerFrame.width - (trashButton.frame.width + 20.0), y: ((footerFrame.height - trashButton.frame.height) / 2)+((exportButton.frame.height - trashButton.frame.height)/2))
        trashButton.addTarget(self, action: #selector(trashButtonPressed), for: .touchUpInside)
        trashButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        footerView.addSubview(trashButton)
        //Creating the add button and adding it to the footer view. We also set it's color. That color is the system blue of the other images.
        let addButton = UIButton(type: .custom)
        addButton.setTitle("Add To", for: .normal)
        addButton.setTitleColor(UIColor.init(red: 0, green: 0.478431, blue: 1, alpha: 1), for: .normal)
        addButton.sizeToFit()
        addButton.frame.origin = CGPoint(x: ((footerFrame.width - addButton.frame.width) / 2), y: (footerFrame.height - addButton.frame.height) / 2)
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        addButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        footerView.addSubview(addButton)
        

            
        let galleryViewController = GalleryViewController(startIndex: indexPath.row, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: self, configuration: galleryConfiguration())
        
        galleryViewController.headerView = headerView
        galleryViewController.footerView = footerView

        
        galleryViewController.landedPageAtIndexCompletion = {index in
            let countString = String(format: stringTemplate, arguments: [index + 1, self.images.count])
            countLabel.attributedText =  NSAttributedString(string: countString, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.black])
            countLabel.sizeToFit()
            countLabel.frame.origin = CGPoint(x: (headerView.frame.width - countLabel.frame.width)/2, y: ((headerView.frame.height - countLabel.frame.size.height)/2 + (statusBarHeight / 2)))
        }
        
        galleryViewController.photoSingleTap = {
            if self.showStatusBar == true{self.showStatusBar = false}
            else {self.showStatusBar = true}
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        backButtonClosure = {
            galleryViewController.closeGallery(true, completion: nil)
        }
        
        trashButtonClosure = {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let destroyAction = UIAlertAction(title: "Delete Photo", style: .destructive, handler: {(action : UIAlertAction!) -> Void in
                let index = Int((countLabel.text?.components(separatedBy: " of ")[0])!)! - 1
                self.images.remove(at: index)
                self.deleteImages([index])
                self.collectionView?.reloadData()
                galleryViewController.removePage(atIndex: index)
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(destroyAction)
            
            galleryViewController.present(alertController, animated: true, completion:nil)
        }
        
        addButtonClosure = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let secondViewController = storyboard.instantiateViewController(withIdentifier: "addToAlbumView")  as! AddToAlbumTableViewController
            secondViewController.originAlbum = self.albumName
            secondViewController.selectedPhotos = [indexPath.row]
            let navController = UINavigationController(rootViewController: secondViewController)
            galleryViewController.present(navController, animated: true, completion: nil)
        }
        
        exportButtonClosure = {
            let index = Int((countLabel.text?.components(separatedBy: " of ")[0])!)! - 1
            var data = FileManager.default.contents(atPath: self.imagesDirectoryPath + "/" + self.imageFileNames[index])
            data?.removeJunkHeader()
            let images = [UIImage(data: data!)]
            let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
            galleryViewController.present(activityViewController, animated: true, completion: nil)
        }
        
        galleryViewController.swipedToDismissCompletion = {self.showStatusBar = true}
        showStatusBar = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.presentImageGallery(galleryViewController)
    }
    }
    
    //MARK: - Gallery Configuration
    var backButtonClosure: (() -> Void) = {}
    func backButtonPressed(){
        backButtonClosure()
    }
    
    var trashButtonClosure: (() -> Void) = {}
    func trashButtonPressed(){
        trashButtonClosure()
    }
    
    var addButtonClosure: (() -> Void) = {}
    func addButtonPressed(){
        addButtonClosure()
    }
    
    var exportButtonClosure: (() -> Void) = {}
    func exportButtonPressed(){
        exportButtonClosure()
    }
    
    var showStatusBar = true
    override var prefersStatusBarHidden: Bool {
        if showStatusBar{return false}
        return true
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.footerViewLayout(.pinBoth(0, 0, 0)),
            GalleryConfigurationItem.headerViewLayout(.pinBoth(0, 0, 0)),
            
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

    
    // MARK: - UIViewControllerPreviewingDelegate
    var selectedCell: IndexPath?
    //Called when an item is peeked at
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //We correct the given location variable by adding the UIscrollView offset to the location
        let correctedLocation = CGPoint(x: location.x, y: location.y + (collectionView?.contentOffset.y)!)
        //We then convert that corrected location into an index path
        guard let indexPath = collectionView?.indexPathForItem(at: correctedLocation) else { return nil }
        selectedCell = indexPath
        //Instantiate the view peek view controller, fetch the image data from disk, and then set the loaded image as the view contorllers image
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return nil }
        var fetchedData = FileManager.default.contents(atPath: self.imagesDirectoryPath.appending("/\(imageFileNames[indexPath.row])"))
        fetchedData?.removeJunkHeader()
        let fetchedImage = UIImage(data: fetchedData!)
        detailVC.photo = fetchedImage
        //Return the peek view controller
        return detailVC
    }
    //Called when an item is popped
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        collectionView(self.collectionView!, didSelectItemAt: selectedCell!)
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    var currentViewController: UIViewController?
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController{
        return currentViewController!
    }

    // MARK: Actions
    var isSelecting = false
    @IBAction func selectButtonPressed(_ sender: UIBarButtonItem) {
        let backButton = self.navigationItem.leftBarButtonItem
        let title = self.navigationItem.title
        let rightButtons = self.navigationItem.rightBarButtonItems
        
        isSelecting = true
        
        //self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.isToolbarHidden = false
        let emptyBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: navigationController, action: nil)
        self.navigationItem.leftBarButtonItem = emptyBackButton
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        cancelButton.style = .done
        self.navigationItem.rightBarButtonItems = [cancelButton]
        self.navigationItem.title = "Select Items"
        
        
        let footerItems = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportButtonPressed)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Add To", style: .plain, target: self, action: #selector(addButtonPressed)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trashButtonPressed))]
        self.navigationController?.toolbar.items = footerItems
        
        cancelButtonClosure = {
            self.navigationItem.leftBarButtonItem = backButton
            self.navigationItem.title = title
            self.navigationItem.rightBarButtonItems = rightButtons
        }
        
        trashButtonClosure = {
            let selectedItems = self.collectionView?.indexPathsForSelectedItems
            if (selectedItems?.count)! > 0 {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                var title = "Delete \(selectedItems!.count) Photos"
                if selectedItems?.count == 1{ title = "Delete Photo" }
                let destroyAction = UIAlertAction(title: title, style: .destructive, handler: {(action : UIAlertAction!) -> Void in
                    let sortedSelectedItems = selectedItems?.sorted{$0.row > $1.row}
                    for indexPath in sortedSelectedItems!{
                        let index = indexPath.row
                        self.images.remove(at: index)
                        self.deleteImages([index])
                        self.collectionView?.reloadData()
                        self.cancelButtonPressed()
                    }
                })
                alertController.addAction(cancelAction)
                alertController.addAction(destroyAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        addButtonClosure = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let secondViewController = storyboard.instantiateViewController(withIdentifier: "addToAlbumView")  as! AddToAlbumTableViewController
            secondViewController.originAlbum = self.albumName
            var newIndexSet = IndexSet()
            for indexPath in (self.collectionView?.indexPathsForSelectedItems)!{
                newIndexSet.insert(indexPath.row)
            }
            secondViewController.selectedPhotos = newIndexSet
            let navController = UINavigationController(rootViewController: secondViewController)
            self.present(navController, animated: true, completion: nil)
            self.cancelButtonPressed()
        }

        exportButtonClosure = {
            let selectedItems = self.collectionView?.indexPathsForSelectedItems
            var images = [UIImage]()
            for indexPath in selectedItems!{
                var data = FileManager.default.contents(atPath: self.imagesDirectoryPath + "/" + self.imageFileNames[indexPath.row])
                data?.removeJunkHeader()
                let image = UIImage(data: data!)
                images.append(image!)
            }
            let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
            self.cancelButtonPressed()
        }


    }
    
    var cancelButtonClosure: (() -> Void) = {}
    func cancelButtonPressed(){
        cancelButtonClosure()
        let selectedItems = self.collectionView?.indexPathsForSelectedItems
        for indexPath in selectedItems!{
            self.collectionView?.deselectItem(at: indexPath, animated: false)
        }
        self.navigationController?.isToolbarHidden = true
        isSelecting = false
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
