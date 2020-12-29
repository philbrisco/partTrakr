//
//  AppDelegate.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/8/20.
//

import Cocoa
import PerfectPostgreSQL

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        // Set up an event handler to close the splash screen
        eventHandler = GlobalEventMonitor(mask: [.leftMouseDown,], handler: {(emouse: NSEvent?) in
            
            if splashController != nil {
                swooshPlayer.play()
                splashController?.close()
                splashController = nil
            }
            eventHandler?.stop()
        })
        eventHandler?.start()
         
        locEventHandler = LocalEventMonitor(mask: [.leftMouseDown,.keyDown], handler: { (NSEvent) -> NSEvent? in
            
            if splashController != nil {
                swooshPlayer.play()
                splashController?.close()
                 splashController = nil
            }
            locEventHandler?.stop()
            
            return NSEvent
        })
        locEventHandler?.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func dbConnector(_ sender: Any) {
        // Only show get db stuff if error alert flag also not set.
        if !getInfoFlag {
            procType = procName.db_name
            getProcInfo("Database Connection", details: "Please enter the database connection name.")
            getInfoFlag = true
        }

        splashController?.window?.close()
        splashController = nil
    }
    
    @IBAction func partList(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "mainWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func dbDisconnector(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil
        p.close()
        p.finish()
        getInfoFlag = false
        clickPlayer.play()
    }

    @IBAction func exitProgram(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil
        // Have to delay the exit or the exit sound won't play.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(self)
        }

        popPlayer.play()
    }
    
    @IBAction func configList(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "configListWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }

    @IBAction func partConfig(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "partConfigWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func configButton(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "configWindowViewController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func partButton(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "partWindowViewController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func maintenanceButton(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "schedMaintWindowController")
        winController.showWindow(self)
        getInfoFlag = false
        
    }
    
    @IBAction func maintTypeMenuItem(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "maintTypeWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func historyMenuItem(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "historyWindowController")
        winController.showWindow(self)
        getInfoFlag = false
        
    }
    
    @IBAction func partLocMenuItem(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
                    showAlert("Database", details: "Database not connected.")
                    return
                }

                swooshPlayer.play()

                let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winController = storyBoard.instantiateController(identifier: "partLocWindowController")
                winController.showWindow(self)
                getInfoFlag = false
        
    }
    
    @IBAction func locationMenuItem(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
                    showAlert("Database", details: "Database not connected.")
                    return
                }

                swooshPlayer.play()

                let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winController = storyBoard.instantiateController(identifier: "locWindowController")
                winController.showWindow(self)
                getInfoFlag = false
        
    }
    
    @IBAction func addrLocButton(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
                    showAlert("Database", details: "Database not connected.")
                    return
                }

                swooshPlayer.play()

                let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winController = storyBoard.instantiateController(identifier: "addressLocWindowController")
                winController.showWindow(self)
                getInfoFlag = false
    }
    
    @IBAction func contactButton(_ sender: Any) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
                    showAlert("Database", details: "Database not connected.")
                    return
                }

                swooshPlayer.play()

                let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winController = storyBoard.instantiateController(identifier: "contactWindowController")
                winController.showWindow(self)
                getInfoFlag = false
    }
    
    @IBAction func contactLocationButton(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
                    showAlert("Database", details: "Database not connected.")
                    return
                }

                swooshPlayer.play()

                let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winController = storyBoard.instantiateController(identifier: "contactLocWindowController")
                winController.showWindow(self)
                getInfoFlag = false
    }
    
    @IBAction func contactDetailButton(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "contactDetWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
    @IBAction func aboutMenuItem(_ sender: NSMenuItem) {
        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        // Ensure that the splash screen is not already up.
        if splashController == nil {
            swooshPlayer.play()

            let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
            splashController = storyBoard.instantiateController(identifier: "splashWindowController")
            splashController!.showWindow(self)
        
            eventHandler?.start()
            locEventHandler?.start()
            getInfoFlag = false
        }
    }
    
    @IBAction func partTypeMenuItem(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "partTypeWindowController")
        winController.showWindow(self)
        getInfoFlag = false
        
    }
    
    @IBAction func configTypeMenuItem(_ sender: NSMenuItem) {
        splashController?.window?.close()
        splashController = nil

        if p.status() == .bad {
            showAlert("Database", details: "Database not connected.")
            return
        }

        swooshPlayer.play()

        let storyBoard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
        winController = storyBoard.instantiateController(identifier: "configTypeWindowController")
        winController.showWindow(self)
        getInfoFlag = false
    }
    
}
