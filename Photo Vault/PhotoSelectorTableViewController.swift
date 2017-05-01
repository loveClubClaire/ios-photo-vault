//
//  PhotoSelectorTableViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/26/17.
//  Copyright © 2017 16^2. All rights reserved.
//


import UIKit
import Photos

class PhotoSelectorTableViewController: UITableViewController {

    struct photoAlbum {
        var identifier:PHAssetCollection
        var name:String
        var thumbnail:UIImage
        var photoCount: Int
    }
    @IBOutlet var errorView: UIView!

    
    var photosCollectionViewController: PhotosCollectionViewController?
    var photoAlbums = [photoAlbum]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        //Access has not been determined.Access has been granted.
        if (status == PHAuthorizationStatus.authorized) {
            photoAlbums = fetchAlbums()
        }
        //Access has not been determined.Access has been denied.
        else if (status == PHAuthorizationStatus.denied) {
            errorView.frame = CGRect(x: 0, y: 65, width: self.view.frame.width, height: self.view.frame.height)
            errorView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            self.navigationController?.view.addSubview(errorView)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "AlbumSelectorCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PhotoSelectorTableViewCell  else {
            fatalError("The dequeued cell is not an instance of PhotoSelectorTableViewCell.")
        }
        
        let album = photoAlbums[indexPath.row]
        cell.albumName.text = album.name + " (" + String(album.photoCount) + ")"
        cell.thumbnail.image = album.thumbnail
        return cell
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)        
        switch (segue.identifier ?? "") {
        case "photoSelectorShowPhotos":
            guard let viewController = segue.destination as? PhotoSelectorCollectionViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedTimerCell = sender as? PhotoSelectorTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            guard let indexPath = tableView.indexPath(for: selectedTimerCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            viewController.images = getAlbumPhotos(anAlbum: photoAlbums[indexPath.row].identifier)
            viewController.imagesAlbum = photoAlbums[indexPath.row].identifier
            viewController.photosCollectionViewController = self.photosCollectionViewController
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    @IBAction func enablePhotoLibrary(_ sender: UIButton) {
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Photo Delegates
    func fetchAlbums() -> [photoAlbum]{
        var result = [photoAlbum]()
        let otherfetchOptions = PHFetchOptions()
        let albums = [PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: otherfetchOptions),PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: otherfetchOptions)]
        for album in albums{
            album.enumerateObjects({ (object, index, stop) -> Void in
                let fetchResult = PHAsset.fetchAssets(in: object, options: nil)
                if fetchResult.count > 0{
                    let thumbnail = self.getAlbumThumbnail(anAlbum: object)
                    let newPhotoAlbum = photoAlbum.init(identifier: object , name: object.localizedTitle!, thumbnail: thumbnail, photoCount: fetchResult.count)
                    result.append(newPhotoAlbum)
                }
            })
        }
        return result
    }
    
    func getAlbumThumbnail(anAlbum: PHAssetCollection) -> UIImage{
        var thumbnail = UIImage()
        let photoAssets = PHAsset.fetchAssets(in: anAlbum, options: nil) as! PHFetchResult<AnyObject>
        let imageManager = PHCachingImageManager()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true

        //TODO: Make this more dynamic
        let imageSize = CGSize(width: 100, height: 100)
        
        imageManager.requestImage(for: photoAssets.lastObject as! PHAsset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {(image, info) -> Void in
            thumbnail = image!
        })
        return thumbnail
    }
    
    func getAlbumPhotos(anAlbum: PHAssetCollection) -> [UIImage]{
        var albumImages = [UIImage]()
        let photoAssets = PHAsset.fetchAssets(in: anAlbum, options: nil) as! PHFetchResult<AnyObject>
        let imageManager = PHImageManager()
        
        photoAssets.enumerateObjects({(object, count, stop) in
            if let asset = object as? PHAsset{
                //Make the image size the exact size of the cell. Do it for speed. "Gotta go fast"
                let itemsPerRow: CGFloat = 4
                var widthPerItem = floor(self.view.frame.width / itemsPerRow)
                if widthPerItem == self.view.frame.width / itemsPerRow {
                    widthPerItem = widthPerItem - 0.5
                }
                let imageSize = CGSize(width: widthPerItem, height: widthPerItem)
                
                /* For faster performance, and maybe degraded image */
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isSynchronous = true
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    albumImages.append(image!)
                })
            }
        })
        return albumImages
    }

}
