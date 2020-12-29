//
//  miscFunctions.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/9/20.
//

import Foundation
import AVFoundation
import Cocoa
import SwiftUI
import PerfectPostgreSQL

var clickPlayer: AVAudioPlayer!
var swooshPlayer: AVAudioPlayer!
var errorPlayer: AVAudioPlayer!
var popPlayer: AVAudioPlayer!

// Generic alert function.
func showAlert (_ message: String, details: String) {
    guard let mySelf = NSApplication.shared.mainWindow else { return }
    if NSApp.keyWindow != nil {
        let alert = NSAlert()

        alert.messageText = message
        alert.informativeText = details
        alert.icon = NSImage(named: "wickedWitch")
        alert.window.minSize = .init(width: 480, height: 200)
        errorPlayer.play()
        
        alert.beginSheetModal(for: mySelf, completionHandler: { response in
            clickPlayer.play()
        })
        getInfoFlag = false
    }
}

// Entry point for procs requiring only one field.  Currently only used when trying
// to connect to the database, but meh.
func getProcInfo (_ message: String, details: String) {
    if let window = NSApp.keyWindow {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let dbField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
        dbField.alignment = .center
        alert.accessoryView = dbField
        alert.window.initialFirstResponder = dbField
        alert.messageText = message
        alert.informativeText = details
        alert.icon = NSImage(named: "Player")
        swooshPlayer.play()

        alert.beginSheetModal(for: window) { (response) in
            getInfoFlag = false
            switch procType {
            case procName.db_name:
                clickPlayer.play()

                // Only if the user presses the "Ok" key should we connect to the DB.
                if response == .alertFirstButtonReturn {
                    connectToDB(dbName: dbField.stringValue)
                }
            default:
                if response == .alertFirstButtonReturn {
          //          connectToDB(dbName: dbField.stringValue)
                }
            }
        }
    }
}

// Entry point to Get info for procs requiring two fields.
// Not currently used, but a rather nifty concept of adding multiple fields and
// other stuff to the alert.
func getTwoProcInfo (_ message: String, details: String, one: String, two: String) {
    
    if let window = NSApp.keyWindow {
        let alert = NSAlert()
        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 350, height: 70))

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let firstLabel = NSTextField(frame: NSRect(x: 0.0, y: 40.0, width: 150.0, height: 24.0))
        let secondLabel = NSTextField(frame: NSRect(x: 200.0, y: 40.0, width: 150.0, height: 24.0))
        let firstField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 150.0, height: 40.0))
        let secondField = NSTextField(frame: NSRect(x: 200.0, y: 0.0, width: 150.0, height: 40.0))

        firstLabel.alignment = .center
        firstLabel.isBezeled = false
        firstLabel.isEditable = false
        firstLabel.isSelectable = false
        firstLabel.drawsBackground = false
        firstLabel.stringValue = one
    
        secondLabel.alignment = .center
        secondLabel.isBezeled = false
        secondLabel.isEditable = false
        secondLabel.isSelectable = false
        secondLabel.drawsBackground = false
        secondLabel.stringValue = two

        stackView.addSubview(firstLabel)
        stackView.addSubview(secondLabel)
        stackView.addSubview(firstField)
        stackView.addSubview(secondField)
    
        firstField.alignment = .center
        secondField.alignment = .center
        firstField.nextResponder = secondField
    
        alert.accessoryView = stackView
        alert.messageText = message
        alert.informativeText = details
        alert.icon = NSImage(named: "Player")
    
        alert.window.initialFirstResponder = firstField
        firstField.nextKeyView = secondField
        secondField.nextKeyView = firstField

        
        alert.beginSheetModal(for: window) { (response) in
            getInfoFlag = false
/*
            switch procType {
            case procName.config_list:
                if response == .alertFirstButtonReturn {
 //                   getConfigList (config_name: firstField.stringValue, ind_type: secondField.stringValue)
                }
            case procName.part_config:
                if response == .alertFirstButtonReturn {
//                    doPartConfig(part_name: firstField.stringValue, config_name: secondField.stringValue)
                }
            case procName.part_list:
                if response == .alertFirstButtonReturn {
//                    getPartList(part_name: firstField.stringValue, ind_type: secondField.stringValue)
                }
            default:
                if response == .alertFirstButtonReturn {
                    //      print ("gothere")
                }
            }
 */
        }
    }
}

// Connect to database.
func connectToDB (dbName: String) {
    // If already connected, skip trying to connect.
    if p.status() == .ok {
        showAlert("Warning", details: "Already connected to database")
    } else {
        let status = p.connectdb("host=localhost dbname=\(dbName)")

        if status != .ok {
            showAlert("\(dbName)", details: "Error connecting to database")
            print ("Error connecting to database.")
        } else {
            getInfoFlag = false
        }
        
    }
    
}

// Generic procedure caller
func doProc (proc_name: String) {
    var finalError = String()

    while (1 == 1) {
        finalError = proc_name
        guard let endOfSentence = proc_name.firstIndex(of: " ") else {break}
        let firstSubString = proc_name[endOfSentence...]
        finalError = String(firstSubString)
        break
    }

    if p.status() == .bad {
        showAlert("Database", details: "Not connected to database.")
    } else {
        let pl = p.exec(statement: proc_name)

        if pl.errorMessage().count > 0 {
            
            while (1 == 1) {
                finalError = pl.errorMessage()
                guard let endOfSentence = pl.errorMessage().lastIndex(of: ":") else { break }
                let firstSentence = pl.errorMessage()[...endOfSentence]
                guard let endOfSecondSentence = firstSentence.lastIndex(of: ".") else { break }
                finalError = String(firstSentence[...endOfSecondSentence])
//                let thisIsIt = String(firstSentence[...endOfSecondSentence])
                break
            }
            
            showAlert("\(finalError)", details: "Procedural Call Error")
        }
        
        pl.clear()
    }
}

// Get the part list
func getPartList (part_name: String, ind_type: String) -> [String]?{
    var partListArr = [String]()
    
    if p.status() == .bad {
        showAlert("Part Listing", details: "Not connected to database.")
        return nil
    } else {
        // if ind_type is blank, default it to true
        let ind_type = (ind_type.count == 0) ? "t" : ind_type
        let pl = p.exec(statement: "call api_part_list($1,$2) ", params: [part_name,ind_type])

        if pl.errorMessage().count > 0 {
            guard let endOfSentence = pl.errorMessage().lastIndex(of: ":") else { return nil}
            let firstSentence = pl.errorMessage()[...endOfSentence]
            guard let endOfSecondSentence = firstSentence.lastIndex(of: ".") else { return nil}
            let thisIsIt = String(firstSentence[...endOfSecondSentence])

            // If the error message is returned from the procedures, then massage
            // the message to get rid of extraneous system stuff.  Otherwise (if it is
            // null or blank), return the whole thing.
            if thisIsIt.count > 0 {
                showAlert("\(part_name)", details: "\(thisIsIt)")
            } else {
                showAlert("\(part_name)", details: "\(pl.errorMessage())")
            }

        } else {
            let res = p.exec(statement: "select tmp_name from mecb_part_tmp")
            let num = res.numTuples()
            
            for x in 0..<num {
                guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return nil}
                partListArr.append(c1)
            }
        
            res.clear()
        }
        
        pl.clear()
    }
    
    return partListArr
}

// Get the config list
func getConfigList (config_name: String, ind_type: String) -> [String]? {
    var configListArr = [String]()
    
    if p.status() == .bad {
        showAlert("Configuration Listing", details: "Not connected to database.")
        return nil
    } else {
        // if ind_type is blank, default it to true
        let ind_type = (ind_type.count == 0) ? "t" : ind_type

        let pl = p.exec(statement: "call api_config_list($1,$2) ", params: [config_name,ind_type])

        if strlen(pl.errorMessage()) > 0 {
            guard let endOfSentence = pl.errorMessage().lastIndex(of: ":") else {return nil}
            let firstSentence = pl.errorMessage()[...endOfSentence]
            guard let endOfSecondSentence = firstSentence.lastIndex(of: ".") else {return nil}
            let thisIsIt = String(firstSentence[...endOfSecondSentence])
 
            // If the error message is returned from the procedures, then massage
            // the message to get rid of extraneous system stuff.  Otherwise (if it is
            // null or blank), return the whole thing.
            if thisIsIt.count > 0 {
                showAlert("\(config_name)", details: "\(thisIsIt)")
            } else {
                showAlert("\(config_name)", details: "\(pl.errorMessage())")
            }
        
        } else {
            let res = p.exec(statement: "select tmp_name from mecb_config_tmp")
            let num = res.numTuples()

            for i in 0..<num {
                guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return nil}
                configListArr.append(c1)
            }
        
            res.clear()
        }
        
        pl.clear()
    }
    
    return configListArr
}

// Set up special effect sounds;
func setupSounds () {
    let clickSound = URL(fileURLWithPath: Bundle.main.path(forResource: "click", ofType: "wav")!)
    let swooshSound = URL(fileURLWithPath: Bundle.main.path(forResource: "swoosh", ofType: "wav")!)
    let errorSound = URL(fileURLWithPath: Bundle.main.path(forResource: "wrongChoice", ofType: "wav")!)
    let popSound = URL(fileURLWithPath: Bundle.main.path(forResource: "pop", ofType: "wav")!)
    do {
        try clickPlayer = AVAudioPlayer(contentsOf: clickSound)
        try swooshPlayer = AVAudioPlayer(contentsOf: swooshSound)
        try errorPlayer = AVAudioPlayer(contentsOf: errorSound)
        try popPlayer = AVAudioPlayer(contentsOf: popSound)
    } catch let error as NSError {
        print ("\(error.localizedDescription)")
    }
    clickPlayer.prepareToPlay()
    swooshPlayer.prepareToPlay()
    errorPlayer.prepareToPlay()
    popPlayer.prepareToPlay()
}

// Turn individual characters into different colors
func rainbowText (targetString: String, doRainbow: Bool, attributes: [NSAttributedString.Key: Any]?, size: CGFloat?) -> NSMutableAttributedString {

    let mySize = (size == nil) ? 12: size!
    var myAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: mySize),
        .foregroundColor: NSColor.black
    ]

    if attributes != nil {
        myAttributes = attributes!
    }
    
    let rangedAttribute = NSMutableAttributedString(string: targetString, attributes: attributes)
    
    if !doRainbow {
        rangedAttribute.addAttributes(myAttributes, range: _NSRange(location: 0, length: targetString.count))
    } else {
        var ranger = 0
    
        for i in 0..<targetString.count {

            ranger = (ranger < 4) ? ranger : 0
        
            switch ranger {
            case 0:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: i, length: 1))
            case 1:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemRed, range: NSRange(location: i, length: 1))
            case 2:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemGray, range: NSRange(location: i, length: 1))
            case 4:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: NSRange(location: i, length: 1))
            default:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: NSRange(location: i, length: 1))
            }
        
            ranger += 1
        }
        
    }
    
    return rangedAttribute
}

func rainbowTextAlt (targetString: String, doRainbow: Bool, attributes: [NSAttributedString.Key: Any]?, size: CGFloat?, length: Int) -> NSMutableAttributedString {

    let mySize = (size == nil) ? 12: size!
    var myAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: mySize),
        .foregroundColor: NSColor.black
    ]

    if attributes != nil {
        myAttributes = attributes!
    }
    
    let rangedAttribute = NSMutableAttributedString(string: targetString, attributes: attributes)
    
    if !doRainbow {
        rangedAttribute.addAttributes(myAttributes, range: _NSRange(location: 0, length: targetString.count))
    } else {
        var finalLength = targetString.count
        var ranger = 0
        
        if length > 0 {
            finalLength = length
        }

        for i in 0..<finalLength {

            ranger = (ranger < 4) ? ranger : 0
        
            switch ranger {
            case 0:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: i, length: 1))
            case 1:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemRed, range: NSRange(location: i, length: 1))
            case 2:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemGray, range: NSRange(location: i, length: 1))
            case 4:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: NSRange(location: i, length: 1))
            default:
                rangedAttribute.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: NSRange(location: i, length: 1))
            }
        
            ranger += 1
        }
        
    }
    
    return rangedAttribute
}
