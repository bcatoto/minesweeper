//
//  MinefieldCollectionViewCell.swift
//  Minesweeper
//
//  Created by Bianca Catoto on 8/21/18.
//  Copyright © 2018 Bianca Catoto. All rights reserved.
//

import UIKit

class MinefieldCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bottomImageView: UIImageView!
    @IBOutlet weak var topImageView: UIImageView!
    var cell:Minefield?
    
    func setField(fieldCell: Minefield) {
        
        // Keep track of field cell that is passed in
        cell = fieldCell;
        
        // Sets image views
        topImageView.image = UIImage(named: "cellover")
        bottomImageView.image = UIImage(named: (cell?.imageName)!)
        bottomImageView.alpha = 1
        
        // Keep track of which field cells have been opened
        if (cell?.isOpen)! {
            topImageView.alpha = 0
        }
        else {
            topImageView.alpha = 1
        }
    }
    
    // Displays flag over cell
    func flag() {
        topImageView.image = UIImage(named: "flag")
        if !(cell?.isMine)! {
            bottomImageView.image = UIImage(named: "wrongflag")
        }
    }
    
    // Removes flag over cell
    func unflag() {
        topImageView.image = UIImage(named: "cellover")
        if !(cell?.isMine)! {
            bottomImageView.image = UIImage(named: (cell?.imageName)!)
        }
    }
    
    // Removes top cell
    func remove() {
        topImageView.alpha = 0
    }
    
    // Replaces mine with exploded mine and removes top cell
    func exploded() {
        bottomImageView.image = UIImage(named: "explodedmine")
        cell?.imageName = "explodedmine"
        remove()
    }
}
