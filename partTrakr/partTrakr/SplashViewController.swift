//
//  SplashViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/26/20.
//
import Foundation
import Cocoa

class SplashViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        let theWidth = self.view.bounds.width
        let theHeight = self.view.bounds.height
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 700, height: 400), display: true)
        self.view.window?.minSize = NSSize(width: 700, height: 400)
        self.view.window?.maxSize = NSSize(width: 700, height: 400)
        self.view.window?.center()

    }

}
