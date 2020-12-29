//
//  SchedMaintViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/19/20.
//

import Foundation
import Cocoa

class SchedMaintViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var firstScroller: NSScrollView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var schedMaintField: NSTextField!
    @IBOutlet weak var maintType: NSTextField!
    @IBOutlet weak var secondScroller: NSScrollView!
    @IBOutlet weak var beginDate: NSDatePickerCell!
    @IBOutlet weak var endDate: NSDatePickerCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        
        firstTable.delegate = self
        firstTable.dataSource = self
        secondTable.delegate = self
        secondTable.dataSource = self
        
        firstTable.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        secondTable.layer?.cornerRadius = 8.0
        secondTable.layer?.masksToBounds = true
      
        var res = p.exec(statement: "select part from mecb_part order by part")
        var num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()

        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        res = p.exec(statement: "select maint_type from mecb_maint_type")
        num = res.numTuples()
                
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }
                
        res.clear()

        firstTable.reloadData()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.6, blue: 0.6, alpha: 1.0)
        schedMaintField.layer?.backgroundColor = .clear
        schedMaintField.backgroundColor = .clear
        self.view.window?.title = "Scheduled Maintenance"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1000, height: 950), display: true)
        self.view.window?.minSize = NSSize(width: 1000, height: 950)
        self.view.window?.maxSize = NSSize(width: 1000, height: 950)
        self.view.window?.center()
        schedMaintField.becomeFirstResponder()
        
        let schedMaintHeader = tableView(firstTable, scrollView: firstScroller, labelName: "Scheduled Maintenance", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(schedMaintHeader)

        let maintTypeHeader = tableView(secondTable, scrollView: secondScroller, labelName: "Maintenance Types", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(maintTypeHeader)
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        schedMaintField.stringValue = ""
        maintType.stringValue = ""
        self.view.window?.close()
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_sched_maint_del('\(schedMaintField.stringValue)', '\(maintType.stringValue)')")
        schedMaintField.stringValue = ""
        maintType.stringValue = ""
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_sched_maint_ins('\(schedMaintField.stringValue)', '\(maintType.stringValue)','\(beginDate.dateValue)','\(endDate.dateValue)')")
        schedMaintField.stringValue = ""
        maintType.stringValue = ""
        
    }
 
    func numberOfRows(in tableView: NSTableView) -> Int {
                
        switch tableView {
        case firstTable:
            return firstPart.count
        default:
            return secondPart.count
        }
            
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        switch tableView {
        case firstTable:
            return firstPart[row]
        default:
            return secondPart[row]
        }
            
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
         if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SchedMaintCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SchedMaintCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {
            
            if firstTable.selectedRow >= 0 {
                clickPlayer.play()

                schedMaintField.stringValue = firstPart[firstTable.selectedRow]
                secondPart.removeAll()
                
                let res = p.exec(statement: "select maint_type from mecb_maint_type")
                let num = res.numTuples()
                        
                for x in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                    secondPart.append(c1)
                }
                        
                res.clear()

                secondTable.reloadData()
                resizedColumn(view: secondTable)
            }

            firstTable.deselectAll(self)
        } else if notification.object as? NSObject == secondTable {
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                maintType.stringValue = secondPart[secondTable.selectedRow]
                secondTable.deselectAll(self)
            }

        }

    }
}

