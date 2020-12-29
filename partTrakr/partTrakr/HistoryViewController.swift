//
//  HistoryViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/19/20.
//

import Foundation
import Cocoa

class HistoryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {

    @IBOutlet weak var firstScroller: NSScrollView!
    @IBOutlet weak var secondScroller: NSScrollView!
    @IBOutlet weak var thirdScroller: NSScrollView!
    
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    @IBOutlet weak var partNameField: NSTextField!
    @IBOutlet weak var maintTypeField: NSTextField!
    @IBOutlet weak var histField: NSTextField!
    @IBOutlet weak var actionDate: NSDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        firstTable.delegate = self
        firstTable.dataSource = self
        secondTable.delegate = self
        secondTable.dataSource = self
        thirdTable.delegate = self
        thirdTable.dataSource = self
        
        firstTable.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        secondTable.layer?.cornerRadius = 8.0
        secondTable.layer?.masksToBounds = true
        thirdTable.layer?.cornerRadius = 8.0
        thirdTable.layer?.masksToBounds = true

        var res = p.exec(statement: "select part from mecb_part order by part")
        var num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()
        thirdPart.removeAll()

        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        res = p.exec(statement: "select maint_type from mecb_maint_type")
        num = res.numTuples()
                
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }
                
        res.clear()

        firstTable.reloadData()
        secondTable.reloadData()
        thirdTable.reloadData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.6, green: 0.1, blue: 0.1, alpha: 1.0)
        partNameField.layer?.backgroundColor = .clear
        partNameField.backgroundColor = .clear
        self.view.window?.title = "Part History"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 900, height: 500), display: true)
        self.view.window?.minSize = NSSize(width: 900, height: 500)
        self.view.window?.maxSize = NSSize(width: 900, height: 500)
        self.view.window?.center()
        partNameField.becomeFirstResponder()
        
        let partHeader = tableView(firstTable, scrollView: firstScroller, labelName: "Parts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(partHeader)

        let maintTypeHeader = tableView(secondTable, scrollView: secondScroller, labelName: "Maintenance Types", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(maintTypeHeader)
        
        let historyHeader = tableView(thirdTable, scrollView: firstScroller, labelName: "History", viewForHeaderInSection: 1)
        thirdTable.headerView?.addSubview(historyHeader)
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_maint_hist_ins('\(partNameField.stringValue)', '\(maintTypeField.stringValue)','\(actionDate.dateValue)', '\(histField.stringValue)')")
        partNameField.stringValue = ""
        maintTypeField.stringValue = ""
        histField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        partNameField.becomeFirstResponder()
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        self.view.window?.close()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
                
        switch tableView {
        case firstTable:
            return firstPart.count
        case secondTable:
            return secondPart.count
        default:
            return thirdPart.count
        }
            
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        switch tableView {
        case firstTable:
            return firstPart[row]
        case secondTable:
            return secondPart[row]
        default:
            return thirdPart[row]
        }

    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == thirdTable {
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HistoryCell3"), owner: self) {

                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
  //                  .foregroundColor: NSColor.black,
  //                  .baselineOffset: 5
                    ]
                let attributeTwo: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.systemGreen
                ]
                let attributesThree: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.systemRed
                ]

                // Find first instance of a space in the string
                guard let startOfSentence = thirdPart[row].firstIndex(of: " ") else {return nil}
                // Find the first instance of a colon in the string
                guard let endOfSentence = thirdPart[row].firstIndex(of: ":") else {return nil}
                // Find the distance between the two indices.
                let string_length = thirdPart[row].distance(from: startOfSentence, to: endOfSentence)
                let rangedAttribute = NSMutableAttributedString(string: thirdPart[row], attributes: myAttributes)
                // The date, which is always prepended to the row is 10 chars.
                rangedAttribute.addAttributes(attributeTwo, range: _NSRange(location: 0, length: 10))
                // We start at the end of the date + q in the string and apply
                // our modifications to the end of the substring.
                rangedAttribute.addAttributes(attributesThree, range: _NSRange(location: 11, length: string_length))

                (cellView as? NSTableCellView)?.textField?.attributedStringValue = rangedAttribute

                return cellView
            }
            
        } else if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HistoryCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
//                     .font: NSFont(name: "Helvetica", size: 18) as Any,
//                     .foregroundColor: NSColor.systemRed
                    
                    :]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HistoryCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont(name: "Helvetica", size: 17) as Any,
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 17)

                return cellView
            }
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {
            
            if firstTable.selectedRow >= 0 {
                clickPlayer.play()

                partNameField.stringValue = firstPart[firstTable.selectedRow]
                secondPart.removeAll()
                
                var res = p.exec(statement: "select maint_type from mecb_maint_type")
                var num = res.numTuples()
                        
                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    secondPart.append(c1)
                }
                        
                res.clear()
                
                thirdPart.removeAll()

                res = p.exec (statement: histVC_maint(part: partNameField.stringValue))
                num = res.numTuples()
                
                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    thirdPart.append(c1)
                }
                
                secondTable.reloadData()
                resizedColumn(view: secondTable)
                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
            }

            firstTable.deselectAll(self)
            maintTypeField.becomeFirstResponder()
        } else if notification.object as? NSObject == secondTable {
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                maintTypeField.stringValue = secondPart[secondTable.selectedRow]
            }

            secondTable.deselectAll(self)
            histField.becomeFirstResponder()
        } else {
            
            if partNameField.stringValue.count == 0 {
                partNameField.becomeFirstResponder()
            } else if maintTypeField.stringValue.count == 0 {
                maintTypeField.becomeFirstResponder()
            } else {
                histField.becomeFirstResponder()
            }
            
            thirdTable.deselectAll(self)
        }

    }
    
}

