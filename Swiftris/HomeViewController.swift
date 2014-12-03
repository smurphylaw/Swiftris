//
//  HomeViewController.swift
//  Swiftris
//
//  Created by Murphy on 12/1/14.
//  Copyright (c) 2014 Murphy. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    var gameController: GameViewController!
    var gamekit: GameKitHelper!
    
    @IBOutlet weak var classicModeButton: UIButton!
    @IBOutlet weak var timedModeButton: UIButton!
    @IBOutlet weak var gameCenterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gamekit = GameKitHelper()
        gamekit.authenticateLocalPlayer(self)
    }
    

    
    @IBAction func gameCenterPreseed(sender: AnyObject) {
        gamekit.showLeaderboardAndAchievement(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        gameController = segue.destinationViewController as GameViewController

        switch (segue.identifier!) {
            case "classicMode":
                gameController.gameMode = .Classic;
            case "timedMode":
                gameController.gameMode = .Timed;
            default:
                println("No Identifiable Game Mode \(segue.identifier)")
        }
    }
}

