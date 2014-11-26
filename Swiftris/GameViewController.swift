//
//  GameViewController.swift
//  Swiftris
//
//  Created by Murphy on 11/11/14.
//  Copyright (c) 2014 Murphy. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate {
    
    var scene: GameScene!
    var swiftris: Swiftris!
    
    var panPointReference:CGPoint?

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        let skView = view as SKView
        skView.multipleTouchEnabled = false
//        skView.gestureRecognizers?.append(self.view.gestureRecognizers!.last)
        
        // Create and configure the scene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        
        swiftris = Swiftris()
        swiftris.delegate = self
        swiftris.beginGame()
        
        // Present the scene
        skView.presentScene(scene)

    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func pauseGame() {
        if (self.scene.view?.paused == true) {
            self.scene.view?.paused = false;
            self.scene.startTicking();
            self.swiftris.timer = NSTimer.scheduledTimerWithTimeInterval(self.swiftris.timeLeftAfterPausing, target: swiftris, selector:Selector("levelUp"), userInfo: nil, repeats: false)
            self.swiftris.timerFinishedAt = NSDate(timeIntervalSinceNow: self.swiftris.timeLeftAfterPausing)
            
        } else {
            self.scene.view?.paused = true;
            self.scene.stopTicking();
            self.swiftris.timer.invalidate();
            self.swiftris.timeLeftAfterPausing = self.swiftris.timerFinishedAt.timeIntervalSinceDate(NSDate())
            
            println("paused with \(swiftris.timeLeftAfterPausing) seconds left")
        }
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        let currentPoint = sender.locationInView(self.view)
        if (true != CGRectContainsPoint(self.pauseButton.frame, currentPoint)) {
            swiftris.rotateShape()
        }
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    swiftris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    swiftris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        swiftris.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let swipeRec = gestureRecognizer as? UISwipeGestureRecognizer {
            if let panRec = otherGestureRecognizer as? UIPanGestureRecognizer {
                return true
            }
        } else if let panRec = gestureRecognizer as? UIPanGestureRecognizer {
            if let tapRec = otherGestureRecognizer as? UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
    func didTick() {
        swiftris.letShapeFall()
    }
    
    func nextShape() {
        let newShapes = swiftris.newShape()
        if let fallingShape = newShapes.fallingShape {
            self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
            self.scene.movePreviewShape(fallingShape) {
                self.view.userInteractionEnabled = true
                self.scene.startTicking()
            }
        }
    }
    
    func gameDidBegin(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(swiftris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(swiftris: Swiftris) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            swiftris.beginGame()
        }
    }
    
    func gameDidLevelUp(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(swiftris: Swiftris) {
        scene.stopTicking()
        scene.redrawShape(swiftris.fallingShape!) {
            swiftris.letShapeFall()
        }
        scene.playSound("drop.mp3")
        
    }
    
    func gameShapeDidLand(swiftris: Swiftris) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(swiftris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks: removedLines.fallenBlocks) {
                self.gameShapeDidLand(swiftris)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(swiftris: Swiftris) {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
    
    
    func authenticateLocalPlayer() {
        var localPlayer = GKLocalPlayer()
        var gameCenterEnabled = Bool()
        
        localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
            if viewController != nil {
                self.presentViewController(viewController, animated: true, completion: nil)
            } else {
                if localPlayer.authenticated {
                    self.gameCenterEnabled = true
                    
                    localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifier : String!, error : NSError!) -> Void in
                        if error != nil {
                            println(error.localizedDescription)
                        } else {
                            self.leaderboardIdentifier = leardboardIdentifier
                        }
                    })
                } else {
                    self.gameCenterEnabled = false
                }
            }
    }
    
}