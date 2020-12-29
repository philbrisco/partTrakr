//
//  MaintenanceTypeViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/18/20.
//

import Foundation
import Cocoa

class MaintenanceTypeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {

    @IBOutlet weak var maintTypeFirstScrollView: NSScrollView!
    @IBOutlet weak var maintTypeSecondScrollView: NSScrollView!
    @IBOutlet weak var maintTypeFirstTable: NSTableView!
    @IBOutlet weak var maintTypeSecondTable: NSTableView!
    @IBOutlet weak var maintTypeName: NSTextField!
    @IBOutlet weak var newMaintTypeName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        maintTypeFirstTable.delegate = self
        maintTypeFirstTable.dataSource = self
        maintTypeSecondTable.delegate = self
        maintTypeSecondTable.dataSource = self
        
        maintTypeFirstTable.layer?.cornerRadius = 8.0
        maintTypeFirstTable.layer?.masksToBounds = true
        maintTypeSecondTable.layer?.cornerRadius = 8.0
        maintTypeSecondTable.layer?.masksToBounds = true

        let res = p.exec(statement: "select maint_type from mecb_maint_type order by maint_type")
        let num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        maintTypeFirstTable.reloadData()

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        maintTypeName.layer?.backgroundColor = .clear
        maintTypeName.backgroundColor = .clear
        let theWidth = self.view.bounds.width/8
        let theHeight = self.view.bounds.height/8
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1000, height: 600), display: true)
        self.view.window?.minSize = NSSize(width: 1000, height: 600)
        self.view.window?.maxSize = NSSize(width: 1000, height: 600)
        self.view.window?.title = "Maintenance Type"
        maintTypeName.becomeFirstResponder()
        
        let maintTypeHeader = tableView(maintTypeFirstTable, scrollView: maintTypeFirstScrollView, labelName: "Maintenance Types", viewForHeaderInSection: 1)
        maintTypeFirstTable.headerView?.addSubview(maintTypeHeader)

        let partHeader = tableView(maintTypeSecondTable, scrollView: maintTypeSecondScrollView, labelName: "Associated Parts", viewForHeaderInSection: 1)
            maintTypeSecondTable.headerView?.addSubview(partHeader)
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        maintTypeName.stringValue = ""
        newMaintTypeName.stringValue = ""
        self.view.window?.close()
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_maint_type_del('\(maintTypeName.stringValue)')")
        maintTypeName.stringValue = ""
        newMaintTypeName.stringValue = ""
        secondPart.removeAll()
        maintTypeSecondTable.reloadData()
        resizedColumn(view: maintTypeSecondTable)

        let res = p.exec(statement: "select maint_type from mecb_maint_type order by maint_type")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        maintTypeFirstTable.reloadData()
        maintTypeName.becomeFirstResponder()
    }

    @IBAction func updateButton(_ sender: NSButton) {
        doProc(proc_name: "call api_maint_type_upd('\(maintTypeName.stringValue)','\(newMaintTypeName.stringValue)')")
        maintTypeName.stringValue = ""
        newMaintTypeName.stringValue = ""
        secondPart.removeAll()
        maintTypeSecondTable.reloadData()
        resizedColumn(view: maintTypeSecondTable)

        let res = p.exec(statement: "select maint_type from mecb_maint_type order by maint_type")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        maintTypeFirstTable.reloadData()
        maintTypeName.becomeFirstResponder()
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
         doProc(proc_name: "call api_maint_type_ins('\(maintTypeName.stringValue)')")
        maintTypeName.stringValue = ""
        newMaintTypeName.stringValue = ""
        secondPart.removeAll()
        maintTypeSecondTable.reloadData()
        resizedColumn(view: maintTypeSecondTable)

        let res = p.exec(statement: "select maint_type from mecb_maint_type order by maint_type")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        maintTypeFirstTable.reloadData()
        maintTypeName.becomeFirstResponder()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
                
        switch tableView {
        case maintTypeFirstTable:
            return firstPart.count
        case maintTypeSecondTable:
            return secondPart.count
        default:
            return 0
        }
            
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        switch tableView {
        case maintTypeFirstTable:
            return firstPart[row]
        default:
            return secondPart[row]
        }
            
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
         if tableView == maintTypeFirstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MaintTypeCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
            // Needs to be at least one row in the second table before we do
            // anything here.
         } else if tableView == maintTypeSecondTable && secondPart.count > 0 {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MaintTypeCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18) as Any,
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == maintTypeFirstTable {
            
            if maintTypeFirstTable.selectedRow >= 0 {
                clickPlayer.play()

                maintTypeName.stringValue = firstPart[maintTypeFirstTable.selectedRow]
                secondPart.removeAll()
                
                let theQuery = maintTypeVC_part (maint_type: maintTypeName.stringValue)
                let res = p.exec(statement: theQuery)
                let num = res.numTuples()
                        
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    secondPart.append(c1)
                    print ("gothere \(c1)")
                }
                        
                res.clear()

                maintTypeSecondTable.reloadData()
                resizedColumn(view: maintTypeSecondTable)
            }

            maintTypeFirstTable.deselectAll(self)
            newMaintTypeName.becomeFirstResponder()
        } else if notification.object as? NSObject == maintTypeSecondTable {
            maintTypeSecondTable.deselectAll(self)
            maintTypeName.becomeFirstResponder()
        }

    }
}
