//
//  ViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/8/20.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "First Window"
        self.view.window?.center()
        self.view.window?.alphaValue = 0.0
        self.view.window?.backgroundColor = .orange
        self.view.isHidden = true
        setupSounds()
        
        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        splashController = storyBoard.instantiateController(identifier: "splashWindowController")
        splashController!.showWindow(self)
        swooshPlayer.play()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

