//
//  PhotosCollectionViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit
import os.log

private let reuseIdentifier = "photoCell"

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var images = [UIImage]()
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
        cell.imageView.image = images[indexPath.row]
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
        print("Hello everyone!")
        print(selectedImages)
    }
    // MARK: - Save and Load
    
    var imageFileNames = [String]()
    
    func saveImages(){
        for index in imageFileNames.count...images.count-1{
            //If file name exists for some reason, make a new one don't overwrite the file
            var title = String(arc4random()) + ".jpg"
            while imageFileNames.contains(title) {
                title = String(arc4random()) + ".jpg"
            }
            imageFileNames.append(title)
            
            let image = images[index]
            let imagePath = imagesDirectoryPath.appending("/\(title)")
            let data = UIImageJPEGRepresentation(image, 1.0)
        
            let success = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
            if success == false {
                os_log("Failed to save image...", log: OSLog.default, type: .error)
            }
        
            let thumbnail = resizeToThumbnail(image: image)
            let thumbnailPath = imagesDirectoryPath.appending("/\(title.components(separatedBy: ".")[0])thumbnail.jpg")
            let thumbnaildata = UIImageJPEGRepresentation(thumbnail, 1.0)
            
            let secondSuccess = FileManager.default.createFile(atPath: thumbnailPath, contents: thumbnaildata, attributes: nil)
            if secondSuccess == false {
                os_log("Failed to save thumbnail...", log: OSLog.default, type: .error)
            }
        }
        NSKeyedArchiver.archiveRootObject(imageFileNames, toFile: imagesDirectoryPath.appending("/pictures"))
        
        
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
    
    func loadImages(){
        imageFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/pictures")) as? [String]) ?? []
        
        for imagePath in imageFileNames{
            let thumbnailPath = imagePath.components(separatedBy: ".")[0] + "thumbnail.jpg"
            let data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(thumbnailPath)"))
            let image = UIImage(data: data!)
            images.append(image!)
        }
    }

    
    // MARK: - UICollectionViewDelegate

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


//Archiving Paths
//    let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
//
//    private func saveImages() {
//        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(images.map{UIImagePNGRepresentation($0)}, toFile: archivePath!)
//        if isSuccessfulSave {
//            os_log("Images successfully saved.", log: OSLog.default, type: .debug)
//        } else {
//            os_log("Failed to save images...", log: OSLog.default, type: .error)
//        }
//    }
//
//    private func loadImages() -> [UIImage]?  {
//        if let dataArray = NSKeyedUnarchiver.unarchiveObject(withFile: archivePath!) as? [NSData] {
//            // Transform the data items to UIImage items
//            let testArray = dataArray.map { UIImage(data: $0 as Data)! }
//            print("\(testArray.count) images loaded.")
//            return testArray
//        } else {
//            print("Failed to load images.")
//            return nil
//        }
//    }
