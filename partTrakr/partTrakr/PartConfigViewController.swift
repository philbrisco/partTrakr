//
//  PartConfigViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/16/20.
//

import Foundation
import Cocoa

class PartConfigViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var thirdScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    @IBOutlet weak var partTextField: NSTextField!
    @IBOutlet weak var configTextField: NSTextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
            // Do view setup here.
        firstTable.delegate = self
        firstTable.dataSource = self

        secondTable.delegate = self
        secondTable.dataSource = self
        
        thirdTable.delegate = self
        thirdTable.dataSource = self

        partTextField.layer?.cornerRadius = 8.0
        partTextField.layer?.masksToBounds = true
        configTextField.layer?.cornerRadius = 8.0
        configTextField.layer?.masksToBounds = true

        firstPart.removeAll()
        secondPart.removeAll()

        let thisQuery = partConfigVC_partsCan()
        
        var res = p.exec(statement: thisQuery)
        var num = res.numTuples()

        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        res = p.exec (statement: "select part from mecb_part where config_id = 0")
        num = res.numTuples()
        
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }

        res.clear()

        firstTable.reloadData()
        secondTable.reloadData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.9, green: 0.6, blue: 0.5, alpha: 1.0)
        let theWidth = self.view.bounds.width/8
        let theHeight = self.view.bounds.height/8
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1000, height: 600), display: true)
        self.view.window?.title = "Part Configuration"
        self.view.window?.minSize = NSSize(width: 900, height: 1000)
        self.view.window?.maxSize = NSSize(width: 900, height: 1000)
//        self.view.window?.center()
        partTextField.becomeFirstResponder()
        let firstPartHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Reconfigurable Parts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(firstPartHeader)

        let secondPartHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Parts Needing Config", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(secondPartHeader)

        let thirdPartHeader = tableView(thirdTable, scrollView: thirdScroll, labelName: "Valid Configurations", viewForHeaderInSection: 1)
        thirdTable.headerView?.addSubview(thirdPartHeader)
    }

    @IBAction func refreshButton(_ sender: Any) {
        doProc(proc_name: "call api_part_config_upd('\(partTextField.stringValue)', '\(configTextField.stringValue)') ")

        let thisQuery = partConfigVC_partsCan()
        firstPart.removeAll()
        var res = p.exec(statement: thisQuery)
        var num = res.numTuples()

        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        secondPart.removeAll()
        res = p.exec (statement: "select part from mecb_part where config_id = 0")
        num = res.numTuples()
        
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }

        res.clear()

        firstTable.reloadData()
        resizedColumn(view: firstTable)
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        partTextField.stringValue = ""
        configTextField.stringValue = ""
    }
        
    @IBAction func closeButton(_ sender: Any) {
        partTextField.stringValue = ""
        configTextField.stringValue = ""
        self.view.window?.close()
    }
        
    func numberOfRows(in tableView: NSTableView) -> Int {
            
        if tableView == firstTable {
            return firstPart.count
        } else if tableView == secondTable {
            return secondPart.count
        } else {
            return thirdPart.count
        }
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            
        if tableView == firstTable {
            return firstPart[row]
        } else if tableView == secondTable {
            return secondPart[row]
        } else {
            return thirdPart[row]
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartConfigCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                    ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else if tableView == secondTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartConfigCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        } else {
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartConfigCell3"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: thirdPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }
/*
    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        return true
    }
*/
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {

            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                partTextField.stringValue =
                        firstPart[firstTable.selectedRow]
                configTextField.stringValue = ""

                var myQuery = partConfigVC_configField(part: partTextField.stringValue)
                var res = p.exec (statement: myQuery)
                var num = res.numTuples()

                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    configTextField.stringValue = c1
                }

                res.clear()

                myQuery = partConfigVC_allConfigs(part: partTextField.stringValue)
                thirdPart.removeAll()
                    
                res = p.exec (statement: myQuery)
                num = res.numTuples()
                    
                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    thirdPart.append(c1)
                }

                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
                res.clear()
            }
            
            firstTable.deselectAll(self)
        } else if notification.object as? NSObject == secondTable {
                
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                partTextField.stringValue =
                        secondPart[secondTable.selectedRow]
                configTextField.stringValue = ""

                var myQuery = partConfigVC_configField(part: partTextField.stringValue)
                var res = p.exec (statement: myQuery)
                var num = res.numTuples()

                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    configTextField.stringValue = c1
                }

                res.clear()

                myQuery = partConfigVC_allConfigs(part: partTextField.stringValue)
                thirdPart.removeAll()
                
                res = p.exec (statement: myQuery)
                num = res.numTuples()
                
                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    thirdPart.append(c1)
                }

                res.clear()
                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
                 
            }
                
            secondTable.deselectAll(self)
        } else if notification.object as? NSObject == thirdTable {
            
            if thirdTable.selectedRow >= 0 {
                clickPlayer.play()
                configTextField.stringValue = thirdPart[thirdTable.selectedRow]
            }
        
            thirdTable.deselectAll(self)
        }
        
    }
}
