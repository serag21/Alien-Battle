//
//  GameViewController.swift
//  Space Battle
//
//  Created by Serag Sorror on 12/28/20.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {

    var backingAudio = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = Bundle.main.path(forResource: "Backing Audio", ofType: "mp3")
        let audioNSURL = NSURL(fileURLWithPath: filePath!)
        
        do { backingAudio = try AVAudioPlayer(contentsOf: audioNSURL as URL)}
        catch { return print("Cannot Find The Audio")}
        
        backingAudio.numberOfLoops = -1
        //backingAudio.volume = 0.85
        backingAudio.play()
        
        if let view = self.view as! SKView? {
            
            //Set default size that applies to all ios devices and scale to fit each respectively
            let scene = MainMenuScene(size: CGSize(width: 1536, height: 2048))
            
            scene.scaleMode = .aspectFill
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            
        }
    }
    

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
