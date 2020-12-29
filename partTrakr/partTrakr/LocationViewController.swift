//
//  LocationViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/21/20.
//

import Foundation
import Cocoa

class LocationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var locationName: NSTextField!
    @IBOutlet weak var newLocationName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        firstTable.delegate = self
        firstTable.dataSource = self
        
        firstTable.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        
        let res = p.exec(statement: "select loc from mecb_loc order by loc")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        firstTable.reloadData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)
        locationName.layer?.backgroundColor = .clear
        locationName.backgroundColor = .clear
        self.view.window?.title = "Locations"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 600, height: 500), display: true)
        self.view.window?.minSize = NSSize(width: 600, height: 500)
        self.view.window?.maxSize = NSSize(width: 600, height: 500)
        self.view.window?.center()
        locationName.becomeFirstResponder()
        
        let locHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Locations", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(locHeader)
        
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_loc_ins('\(locationName.stringValue)')")
        
        // Ensure there was no error before updating the table.
        if p.errorMessage().count == 0 {
            firstPart.append(locationName.stringValue)
            firstPart.sort()
        }
        
        locationName.stringValue = ""
        newLocationName.stringValue = ""
        firstTable.reloadData()
        resizedColumn(view: firstTable)
    }
    
    @IBAction func updateButton(_ sender: NSButton) {
        doProc(proc_name: "call api_loc_upd('\(locationName.stringValue)','\(newLocationName.stringValue)')")
        
        let res = p.exec(statement: "select loc from mecb_loc order by loc")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        locationName.stringValue = ""
        newLocationName.stringValue = ""
        firstTable.reloadData()
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_loc_del('\(locationName.stringValue)')")
        
        let res = p.exec(statement: "select loc from mecb_loc order by loc")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        locationName.stringValue = ""
        newLocationName.stringValue = ""
        firstTable.reloadData()
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        locationName.stringValue = ""
        self.view.window?.close()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        firstPart.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return firstPart[row]
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LocationCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {

            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                locationName.stringValue = firstPart[firstTable.selectedRow]
            }
            
            firstTable.deselectAll(self)
            newLocationName.becomeFirstResponder()
        }
        
    }
}
