//
//  AlbumTableViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit
import os.log

class AlbumTableViewController: UITableViewController {

    var albums = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albums = UserDefaults.standard.array(forKey: "masterKey") as? [String] ?? []
        self.navigationItem.title = "Albums"
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

         //Display an Edit button in the navigation bar for this view controller.
         navigationItem.leftBarButtonItem = editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "AlbumTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AlbumTableViewCell else{
            fatalError("The dequeued cell is not an instance of AlbumTableViewCell.")
        }

        // Configure the cell...
        cell.albumNameLabel.text = albums[indexPath.row]
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Delete Album?", message: "The photos within the album will be deleted", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let destroyAction = UIAlertAction(title: "Delete", style: .destructive, handler: {(action : UIAlertAction!) -> Void in
                // Remove the images from the applciation
                UserDefaults.standard.set(nil, forKey: "\(self.albums[indexPath.row])photoTimeStamps")
                let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
                let imagesDirectoryPath = documentsDirectory.appending("/Photos")
                let imageFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/\(self.albums[indexPath.row])_albumPictures")) as? [String]) ?? []
                for imagePath in imageFileNames {
                    let thumbnailPath = imagePath.components(separatedBy: ".")[0] + "thumbnail.jpg"
                    do {
                        try FileManager.default.removeItem(atPath: imagesDirectoryPath.appending("/\(thumbnailPath)"))
                        try FileManager.default.removeItem(atPath: imagesDirectoryPath.appending("/\(imagePath)"))
                    }
                    catch{
                        os_log("Failed to delete image & thumbnail...", log: OSLog.default, type: .error)
                    }
                }
                if imageFileNames != []{
                    try! FileManager.default.removeItem(atPath: imagesDirectoryPath.appending("/\(self.albums[indexPath.row])_albumPictures"))
                }
                // Delete the row from the data source
                self.albums.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                UserDefaults.standard.set(self.albums, forKey: "masterKey")
            })
            alertController.addAction(cancelAction)
            alertController.addAction(destroyAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    

    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let movingItem = albums[fromIndexPath.row]
        albums.remove(at: fromIndexPath.row)
        albums.insert(movingItem, at: to.row)
        UserDefaults.standard.set(albums, forKey: "masterKey")
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        self.navigationController?.setToolbarHidden(true, animated: false)
        switch (segue.identifier ?? "") {
        case "showPhotos":
            guard let viewController = segue.destination as? PhotosCollectionViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedTimerCell = sender as? AlbumTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            guard let indexPath = tableView.indexPath(for: selectedTimerCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            viewController.albumName = albums[indexPath.row]
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    // MARK: - Actions
    var saveButton: UIAlertAction? = nil
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {

        let alertController = UIAlertController(title: "New Album", message: "Enter a name for this album", preferredStyle: .alert)
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Title"
            textField.autocapitalizationType = .sentences
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
        })
        
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
            alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            self.albums.append(firstTextField.text!)
            UserDefaults.standard.set(self.albums, forKey: "masterKey")
            self.tableView.reloadData()
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        alertController.actions[1].isEnabled = false
        saveButton = alertController.actions[1]
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField.text != "" {
            saveButton?.isEnabled = true
        }
        else{
            saveButton?.isEnabled = false
        }
    }
    
    //MARK: - Overrides
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
