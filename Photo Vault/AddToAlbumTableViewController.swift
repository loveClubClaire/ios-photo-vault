//
//  AddToAlbumTableViewController.swift
//  
//
//  Created by Zachary Whitten on 3/23/17.
//
//

import UIKit

class AddToAlbumTableViewController: UITableViewController {

    var albums = [String]()
    
    var originAlbum: String?
    var selectedPhotos: IndexSet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albums = UserDefaults.standard.array(forKey: "masterKey") as? [String] ?? []
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
       
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
        let cellIdentifier = "AddToAlbumTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AlbumTableViewCell else{
            fatalError("The dequeued cell is not an instance of AlbumTableViewCell.")
        }
        
        // Configure the cell...
        cell.albumNameLabel.text = albums[indexPath.row]
        return cell
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Get the origin albums image file names
        let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
        let imagesDirectoryPath = documentsDirectory.appending("/Photos")
        let originFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/\(originAlbum!)_albumPictures")) as? [String]) ?? []
        //Get an array of the origin albums selected image file names
        var selectedFileNames = [String]()
        for index in selectedPhotos!{
            selectedFileNames.append(originFileNames[index])
        }
        //Get the destination albums image file names
        let destinationAlbum = (tableView.cellForRow(at: indexPath) as! AlbumTableViewCell).albumNameLabel.text
        var destinationFileNames = (NSKeyedUnarchiver.unarchiveObject(withFile: imagesDirectoryPath.appending("/\(destinationAlbum!)_albumPictures")) as? [String]) ?? []
        //Append the origin albums selected image file names to the destination albums image file names
        destinationFileNames.append(contentsOf: selectedFileNames)
        //Save the new destinationFileNames
        NSKeyedArchiver.archiveRootObject(destinationFileNames, toFile: imagesDirectoryPath.appending("/\(destinationAlbum!)_albumPictures"))
        
        dismiss(animated: true, completion: nil)
    }

}
