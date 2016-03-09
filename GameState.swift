//
//  GameState.swift
//  FaceMock
//
//  Created by Swamy on 2/22/16.
//  Copyright © 2016 Ran Tech. All rights reserved.
//

import Foundation

class GameState {
    
    var score: Int
    var highScore: Int
    var stars: Int
    
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        
        return Singleton.instance
    }
    
    init() {
        // Init
        score = 0
        highScore = 0
        stars = 0
        
        // Load game state
        let defaults = NSUserDefaults.standardUserDefaults()
        
        highScore = defaults.integerForKey("highScore")
        stars = defaults.integerForKey("stars")
    }
    
    func saveState() {
        // Update highScore if the current score is greater
        highScore = max(score, highScore)
        
        // Store in user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(highScore, forKey: "highScore")
        defaults.setInteger(stars, forKey: "stars")
        NSUserDefaults.standardUserDefaults().synchronize()
    }}
