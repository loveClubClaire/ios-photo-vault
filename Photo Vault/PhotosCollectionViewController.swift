//
//  PhotosCollectionViewController.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/23/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import UIKit


private let reuseIdentifier = "Cell"

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var selectedImages = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 20
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
        cell.backgroundColor = UIColor.black
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
