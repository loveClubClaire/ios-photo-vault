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
    
    var passedAlbum: String?
    var selectedPhotos: IndexSet?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        albums = ["Hello","World"]
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
        
        
         dismiss(animated: true, completion: nil)
    }

}
