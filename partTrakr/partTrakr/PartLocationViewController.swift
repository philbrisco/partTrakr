//
//  PartLocationViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/23/20.
//

import Cocoa

class PartLocationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    private var locTypeArr = [String]()
    
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var thirdScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    
    @IBOutlet weak var partField: NSTextField!
    @IBOutlet weak var locationTypeField: NSTextField!
    @IBOutlet weak var locationField: NSTextField!

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
        locTypeArr.removeAll()
        thirdPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        res = p.exec(statement: "select loc_type, description from mecb_loc_type order by loc_type_id")
        num = res.numTuples()

        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            locTypeArr.append(c1)
            guard let c2 = res.getFieldString(tupleIndex: i, fieldIndex: 1) else {return}
            secondPart.append(c2)
        }
            
        res.clear()
        
        res = p.exec(statement: "select loc from mecb_loc")
        num = res.numTuples()
    
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            thirdPart.append(c1)
        }
        
        firstTable.reloadData()
        secondTable.reloadData()
        thirdTable.reloadData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.75, blue: 0.5, alpha: 1.0)
        self.view.window?.title = "Part Locations"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 600, height: 500), display: true)
        self.view.window?.minSize = NSSize(width: 600, height: 500)
        self.view.window?.maxSize = NSSize(width: 600, height: 500)
        self.view.window?.center()
        partField.becomeFirstResponder()

        let partHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Parts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(partHeader)
        
        let locTypeHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Location Types", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(locTypeHeader)

        let locHeader = tableView(thirdTable, scrollView: thirdScroll, labelName: "Locations", viewForHeaderInSection: 1)
        thirdTable.headerView?.addSubview(locHeader)

    }
    
    @IBAction func insertButton (_ sender: NSButton) {
        doProc(proc_name: "call api_part_loc_ins('\(partField.stringValue)','\(locationField.stringValue)','\(locationTypeField.stringValue)')")
        partField.stringValue = ""
        locationTypeField.stringValue = ""
        locationField.stringValue = ""
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
    }
    
    @IBAction func deleteButton (_ sender: NSButton) {
        doProc(proc_name: "call api_part_loc_del('\(partField.stringValue)','\(locationField.stringValue)')")
        partField.stringValue = ""
        locationTypeField.stringValue = ""
        locationField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }
    
    @IBAction func closeButton (_ sender: NSButton) {
        firstPart.removeAll()
        secondPart.removeAll()
        locTypeArr.removeAll()
        thirdPart.removeAll()
        partField.stringValue = ""
        locationTypeField.stringValue = ""
        locationField.stringValue = ""
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
        
        switch tableView {
        case firstTable:

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartLocCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        case secondTable:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartLocCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        default:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartLocCell3"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: thirdPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        switch notification.object as? NSObject {
        case firstTable:
            
            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                partField.stringValue = firstPart[firstTable.selectedRow]
            
                secondPart.removeAll()
                locTypeArr.removeAll()
                var res = p.exec(statement: "select loc_type, description from mecb_loc_type")
                var num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    locTypeArr.append(c1)
                    guard let c2 = res.getFieldString(tupleIndex: i, fieldIndex: 1) else {return}
                    secondPart.append(c2)
                }
                
                res.clear()
            
                thirdPart.removeAll()
                res = p.exec(statement: "select loc from mecb_loc")
                num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    thirdPart.append(c1)
                }
       
                locationField.stringValue = ""
                let theQuery = partLocVC_loc(part: partField.stringValue, locType: locationTypeField.stringValue)
                res = p.exec(statement: theQuery)
                
                num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    locationField.stringValue = c1
                }

                partField.stringValue = firstPart[firstTable.selectedRow]
                secondTable.reloadData()
                resizedColumn(view: secondTable)
                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
            }
            
            firstTable.deselectAll(self)
            locationTypeField.becomeFirstResponder()
        case secondTable:
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                locationTypeField.stringValue = locTypeArr[secondTable.selectedRow]
                
                locationField.stringValue = ""
                let theQuery = partLocVC_loc(part: partField.stringValue, locType: locationTypeField.stringValue)
                let res = p.exec(statement: theQuery)
                
                let num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    locationField.stringValue = c1
                }

            }
            
            secondTable.deselectAll(self)
            locationField.becomeFirstResponder()
        default:
            
            if thirdTable.selectedRow >= 0 {
                clickPlayer.play()
                locationField.stringValue = thirdPart[thirdTable.selectedRow]
            }
            
            thirdTable.deselectAll(self)
            partField.becomeFirstResponder()
        }

    }
}
