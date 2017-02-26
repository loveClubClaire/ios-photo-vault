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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: - Photo Delegates
    func fetchAlbums(){
        
        let otherfetchOptions = PHFetchOptions()
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: otherfetchOptions)
        smartAlbums.enumerateObjects({ (object, index, stop) -> Void in
            
            let fetchResult = PHAsset.fetchAssets(in: object, options: nil)
            
            if fetchResult.count > 0{
                print(object.localizedTitle ?? "Null Value")
                let images = self.getAlbumPhotos(anAlbum: object)
            }
            
        })
        
        
        
        
        //        let fetchOptions = PHFetchOptions()
        //        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //        collection.enumerateObjects({ (object, index, stop) -> Void in
        //            if object.estimatedAssetCount != 0{
        //                print(object.localizedTitle ?? "Null Value")
        //            }
        //        })
    }
    
    func getAlbumPhotos(anAlbum: PHAssetCollection) -> [UIImage]{
        var albumImages = [UIImage]()
        let photoAssets = PHAsset.fetchAssets(in: anAlbum, options: nil) as! PHFetchResult<AnyObject>
        let imageManager = PHCachingImageManager()
        
        photoAssets.enumerateObjects({(object, count, stop) in
            if let asset = object as? PHAsset{
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                /* For faster performance, and maybe degraded image */
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isSynchronous = true
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    albumImages.append(image!)
                    //print(info ?? "No Info")
                })
            }
        })
        return albumImages
    }

}
