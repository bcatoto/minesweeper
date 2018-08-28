//
//  ViewController.swift
//  Minesweeper
//
//  Created by Bianca Catoto on 8/21/18.
//  Copyright © 2018 Bianca Catoto. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var minefield = [Minefield]()
    var model = MinesweeperModel()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Difficulty
    var numberOfCells = 64
    var numberOfMines = 10
    var minesLeft = 10
    var n = 8
    var nextGame = [64, 10]
    
    // Buttons
    @IBOutlet weak var easy: UIButton!
    @IBOutlet weak var medium: UIButton!
    @IBOutlet weak var hard: UIButton!
    @IBOutlet weak var flagButton: UIButton!
    
    // Keeps track of number of surrounding flags
    var flags = 0
    var flagMode = false
    var gameOver = false
    var newGameStarted = false
    
    // Stopwatch
    @IBOutlet weak var stopwatchLabel: UILabel!
    var stopwatch:Timer?
    var milliseconds:Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        newGame()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func newGame() {
        
        // Set up new minefield
        minefield = model.getMinefield(numberOfCells: numberOfCells, numberOfMines: numberOfMines)
        
        // Sets insets for collection view to properly layout minefield grid
        let flow = UICollectionViewFlowLayout()
        
        // Calculate horizontal and vertical insets
        let horInsets = (view.frame.size.width - CGFloat(24 * n)) / CGFloat(2)
        let verInsets = (view.frame.size.height - 210 - CGFloat(24 * n)) / CGFloat(2)
        
        // Apply values
        flow.sectionInset = UIEdgeInsets(top: verInsets - 30, left: horInsets, bottom: verInsets, right: horInsets)
        flow.itemSize = CGSize(width: 24, height: 24)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(flow, animated: false)
        
        // Reloads collection view with new data if new game
        if newGameStarted {
            collectionView.reloadData()
        }
        
        // Set delegates
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Create stopwatch
        self.stopwatch = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(stopwatchElapsed), userInfo: nil, repeats: true)
        RunLoop.main.add(stopwatch!, forMode: .commonModes)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfCells
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MinefieldCell", for: indexPath) as! MinefieldCollectionViewCell
        let field = minefield[indexPath.row]
        cell.setField(fieldCell: field)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! MinefieldCollectionViewCell
        let field = minefield[indexPath.row]
        
        // Does nothing if game is over to prevent player from continuing game
        if gameOver {
            return
        }
        
        if field.isOpen {
            if field.neighborMine == 0 {
                // Toggles flag mode when blank, open field is tapped
                toggleFlagMode()
            }
            else {
                // Open surronding cells if all surrounding mines have been correctly flagged
                
                let rowNum = row(indexPath.row)
                let colNum = col(indexPath.row)
                let rows = [rowNum - 1, rowNum - 1, rowNum - 1, rowNum, rowNum, rowNum + 1, rowNum + 1, rowNum + 1]
                let cols = [colNum - 1, colNum, colNum + 1, colNum - 1, colNum + 1, colNum - 1, colNum, colNum + 1]
                flags = 0
                
                // Check if surrounding cells have been correctly flagged
                var minesFlagged = true
                
                for i in 0...7 {
                    minesFlagged = minesFlagged && correctMinesFlagged(row: rows[i], col: cols[i])
                }
                
                // Removes surrounding cells if they don't contain mines
                if minesFlagged {
                    for i in 0...7 {
                        removeNeighborCell(row: rows[i], col: cols[i])
                    }
                }
                else if flags >= field.neighborMine! {
                    gameOver(won: false)
                }
            }
        }
        else if flagMode {
            if !field.isFlagged {
                // If field cell is not flagged and not open, flag it
                cell.flag()
                field.isFlagged = true
                
                // If flagged cell contains a mine, decrease number of mines left
                if field.isMine {
                    minesLeft -= 1
                }
                
                // If all the mines are flagged, game over and player wins
                if minesLeft == 0 {
                    gameOver(won: true)
                }
            }
            else {
                // If field cell is flagged, unflag it
                cell.unflag()
                field.isFlagged = false
                
                // If field cell unflagged contains mine, increase mines left
                if field.isMine {
                    minesLeft += 1
                }
            }
        }
        else {
            if !field.isMine {
                if field.neighborMine == 0 {
                    // If cell is blank, open all surrounding blank cells
                    removeBlanks(row: indexPath.row / n, col: indexPath.row % n)
                }
                else {
                    // Remove top cell and declare cell open
                    cell.remove()
                    field.isOpen = true
                }
            }
            else {
                // If removed field contains a mine, game is over and user loses
                cell.exploded()
                gameOver(won: false)
            }
        }
    }
    
    // MARK: Game Logic
    
    // Checks if cell is a mine and is flagged or isn't a mine and isn't flagged
    func correctMinesFlagged(row: Int, col: Int) -> Bool {
        if validate(row: row, col: col) {
            let field = minefield[index(row, col)]
            
            // Keeps track of number of surrounding flags
            if field.isFlagged {
                flags += 1
            }
            
            if field.isOpen {
                return true
            }
            else if field.isMine {
                return field.isFlagged
            }
            else {
                return !field.isFlagged
            }
        }
        
        return true
    }
    
    // Remove surrounding non-mine cells if number is tapped and all surrounding mines are flagged
    func removeNeighborCell(row: Int, col: Int) {
        if validate(row: row, col: col) {
            let cell = collectionView.cellForItem(at: IndexPath(row: index(row, col), section: 0)) as! MinefieldCollectionViewCell
            let field = minefield[index(row, col)]
            
            if (!field.isMine) {
                if field.neighborMine == 0 {
                    removeBlanks(row: row, col: col)
                }
                else {
                    cell.remove()
                    field.isOpen = true
                }
            }
        }
    }
    
    // Removes adjacent cells that are not mines
    func removeBlanks(row: Int, col: Int) {
        if validate(row: row, col: col) {
            let cell = collectionView.cellForItem(at: IndexPath(row: index(row, col), section: 0)) as! MinefieldCollectionViewCell
            let field = minefield[index(row, col)]
            
            if !field.isOpen && !field.isMine {
                // Opens none mine cells
                cell.remove()
                field.isOpen = true
                
                if field.neighborMine == 0 {
                    // Continues removing if current cell is blank
                    removeBlanks(row: row - 1, col: col)
                    removeBlanks(row: row + 1, col: col)
                    removeBlanks(row: row, col: col - 1)
                    removeBlanks(row: row, col: col + 1)
                    
                    // Continue recurring corners if corner cells are blank
                    removeCornerBlanks(row: row - 1, col: col - 1)
                    removeCornerBlanks(row: row - 1, col: col + 1)
                    removeCornerBlanks(row: row + 1, col: col - 1)
                    removeCornerBlanks(row: row + 1, col: col + 1)
                    
                    // Only remove non-mine corner cells if current cell is blank
                    removeCornerNeighbors(row: row - 1, col: col - 1)
                    removeCornerNeighbors(row: row - 1, col: col + 1)
                    removeCornerNeighbors(row: row + 1, col: col - 1)
                    removeCornerNeighbors(row: row + 1, col: col + 1)
                }
            }
        }
    }
    
    // Removes corner cells and continues recurring only if corner cells are blank
    func removeCornerBlanks(row: Int, col: Int) {
        if validate(row: row, col: col) {
            let field = minefield[index(row, col)]
            
            if !field.isOpen && field.neighborMine == 0 {
                removeBlanks(row: row, col: col)
            }
        }
    }
    
    // Removes corner cells that are not mines and not blank
    func removeCornerNeighbors(row: Int, col: Int) {
        if validate(row: row, col: col) {
            let cell = collectionView.cellForItem(at: IndexPath(row: index(row, col), section: 0)) as! MinefieldCollectionViewCell
            let field = minefield[index(row, col)]
            
            if !field.isOpen && !field.isMine && field.neighborMine! > 0 {
                cell.remove()
                field.isOpen = true
            }
        }
    }
    
    // Toggle flag mode
    func toggleFlagMode() {
        flagMode = !flagMode
        
        if flagMode {
            flagButton.setImage(UIImage(named: "flagbuttontoggled"), for: .normal)
        }
        else {
            flagButton.setImage(UIImage(named: "flagbutton"), for: .normal)
        }
    }
    
    // Game over function
    func gameOver(won: Bool) {
        // Stop stopwatch
        self.stopwatch?.invalidate()
        
        // Sets game over to true so player cannot continue playing
        gameOver = true
        
        // Set title and message of game over alerts
        var title = ""
        var message = ""
        
        if won {
            // Win board: opens all cells that are not mines
            for i in 0..<minefield.count {
                if !minefield[i].isOpen && !minefield[i].isMine {
                    let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as! MinefieldCollectionViewCell
                    cell.remove()
                }
            }
            
            title = "Congratulations!"
            let seconds = String(format: "%.2f", milliseconds/1000)
            message = "You finished in \(seconds) seconds"
        }
        else {
            // Lose board: opens all remaining non-flagged mines and displays which cells were incorrect flagged
            for i in 0..<minefield.count {
                if (minefield[i].isMine && !minefield[i].isFlagged) || (!minefield[i].isMine && minefield[i].isFlagged) {
                    let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as! MinefieldCollectionViewCell
                    cell.remove()
                }
            }
            
            title = "BOOM!"
            message = "You've lost"
        }
        
        // Show game over message
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
        
        self.stopwatch?.invalidate()
    }
    
    // MARK: Game Buttons
    
    // Starts new game when New Game button is tapped
    @IBAction func newGame(_ sender: Any) {
        numberOfCells = nextGame[0]
        numberOfMines = nextGame[1]
        minesLeft = numberOfMines
        n = Int(sqrt(Double(numberOfCells)))
        
        newGameStarted = true
        gameOver = false
        milliseconds = 0
        
        model = MinesweeperModel()
        newGame()
    }
    
    // Toggles flag mode when Flag Button is tapped
    @IBAction func flagButton(_ sender: UIButton) {
        toggleFlagMode()
    }
    
    // Sets up next game in easy mode
    @IBAction func easy(_ sender: UIButton) {
        sender.setImage(UIImage(named: "easytoggled"), for: .normal)
        nextGame = [64, 10]
        
        medium.setImage(UIImage(named: "medium"), for: .normal)
        hard.setImage(UIImage(named: "hard"), for: .normal)
    }
    
    // Sets up next game in medium mode
    @IBAction func medium(_ sender: UIButton) {
        sender.setImage(UIImage(named: "mediumtoggled"), for: .normal)
        nextGame = [121, 20]
        
        easy.setImage(UIImage(named: "easy"), for: .normal)
        hard.setImage(UIImage(named: "hard"), for: .normal)
    }
    
    // Sets up next game in hard mode
    @IBAction func hard(_ sender: UIButton) {
        sender.setImage(UIImage(named: "hardtoggled"), for: .normal)
        nextGame = [196, 35]
        
        easy.setImage(UIImage(named: "easy"), for: .normal)
        medium.setImage(UIImage(named: "medium"), for: .normal)
    }
    
    // MARK: Timer Method
    
    @objc func stopwatchElapsed() {
        milliseconds += 1
        
        // Convert to seconds
        let seconds = String(format: "%.2f", milliseconds/1000)
        
        // Set label
        stopwatchLabel.text = "Time\n\(seconds)"
    }
    
    // MARK: Helper Methods
    
    // Converts row and col to index
    func index(_ row: Int, _ col: Int) -> Int {
        return row * n + col
    }
    
    // Converts index to row
    func row(_ index: Int) -> Int {
        return index / n
    }
    
    // Converts index to col
    func col(_ index: Int) -> Int {
        return index % n
    }
    
    // Validates row and col are in bounds
    func validate(row: Int, col: Int) -> Bool {
        if row > -1 && row < n && col > -1 && col < n {
            return true
        }
        
        return false
    }
}
