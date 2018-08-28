//
//  MinesweeperModel.swift
//  Minesweeper
//
//  Created by Bianca Catoto on 8/21/18.
//  Copyright © 2018 Bianca Catoto. All rights reserved.
//

import Foundation

class MinesweeperModel {
    
    var minefield = [Minefield]()
    var n = 0
    
    func getMinefield(numberOfCells: Int, numberOfMines: Int) -> [Minefield] {
        
        n = Int(sqrt(Double(numberOfCells)))
        
        // Insert mines
        for _ in 1...numberOfMines {
            let field = Minefield()
            field.isMine = true
            field.imageName = "mine"
            minefield.append(field)
        }
        
        // Insert remaining minefield cells
        for _ in 1...(numberOfCells - numberOfMines) {
            let field = Minefield()
            field.neighborMine = 0
            field.imageName = "blank"
            minefield.append(field)
        }
        
        // Randomize mines in minefield
        for i in 0..<numberOfCells {
            let randomNumber = Int(arc4random_uniform(UInt32(numberOfCells)))
            let temp = minefield[randomNumber]
            minefield[randomNumber] = minefield[i]
            minefield[i] = temp
        }
        
        // Calculates number of neighboring mines
        for i in 0..<numberOfCells {
            if minefield[i].isMine {
                countMines(row: i / n - 1, col: i % n - 1)
                countMines(row: i / n - 1, col: i % n)
                countMines(row: i / n - 1, col: i % n + 1)
                countMines(row: i / n, col: i % n - 1)
                countMines(row: i / n, col: i % n + 1)
                countMines(row: i / n + 1, col: i % n - 1)
                countMines(row: i / n + 1, col: i % n)
                countMines(row: i / n + 1, col: i % n + 1)
            }
        }
        
        return minefield
    }
    
    func countMines(row: Int, col: Int) {
        if (row > -1 && row < n && col > -1 && col < n && !minefield[row * n + col].isMine) {
            let field = minefield[row * n + col]
            field.neighborMine! += 1
            field.imageName = "\(field.neighborMine!)"
        }
    }
}
