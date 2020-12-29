//
//  ContactLocationViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/25/20.
//

import Cocoa

class ContactLocationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var thirdScroll: NSScrollView!
    
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    
    @IBOutlet weak var contactField: NSTextField!
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
        
        var res = p.exec(statement: "select contact from mecb_contact order by contact")
        var num = res.numTuples()
        
        firstPart.removeAll()
        secondPart.removeAll()
        thirdPart.removeAll()
        contactField.stringValue = ""
        locationField.stringValue = ""
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        res = p.exec(statement: "select loc from mecb_loc order by loc")
        num = res.numTuples()

        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            thirdPart.append(c1)
        }
        
        firstTable.reloadData()
        resizedColumn(view: firstTable)
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        self.view.window?.title = "Contact Locations"
        let theWidth = self.view.bounds.width/2
        let theHeight = self.view.bounds.height/2
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 918, height: 520), display: true)
        self.view.window?.minSize = NSSize(width: 918, height: 520)
        self.view.window?.maxSize = NSSize(width: 918, height: 520)
        self.view.window?.center()
        contactField.becomeFirstResponder()

        let contactHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Contacts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(contactHeader)
        
        let locHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Contact Locations", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(locHeader)
        
        let allLocHeader = tableView(thirdTable, scrollView: secondScroll, labelName: "All Locations", viewForHeaderInSection: 1)
        thirdTable.headerView?.addSubview(allLocHeader)

    }
    
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_loc_ins('\(contactField.stringValue)','\(locationField.stringValue)')")
        
        contactField.stringValue = ""
        locationField.stringValue = ""
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_loc_del('\(contactField.stringValue)', '\(locationField.stringValue)')")
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        
        contactField.becomeFirstResponder()
        contactField.stringValue = ""
        locationField.stringValue = ""
    }
    
    @IBAction func clearFieldsButton(_ sender: NSButton) {
        contactField.stringValue = ""
        locationField.stringValue = ""
        contactField.becomeFirstResponder()
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        contactField.stringValue = ""
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactLocCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        case secondTable:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactLocCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }

        default:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactLocCell3"), owner: self) {
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
                contactField.stringValue = firstPart[firstTable.selectedRow]
            
                secondPart.removeAll()
                let res = p.exec(statement: "\(contactLocVC_loc(contact: contactField.stringValue))")
                let num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    secondPart.append(c1)
                }
        
                secondTable.reloadData()
                resizedColumn(view: secondTable)
            }
            
            locationField.stringValue = ""
            firstTable.deselectAll(self)
            locationField.becomeFirstResponder()

        case secondTable:
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                locationField.stringValue = secondPart[secondTable.selectedRow]
            }
            
            contactField.becomeFirstResponder()
            
        default:
            
            if thirdTable.selectedRow >= 0 {
                clickPlayer.play()
                locationField.stringValue = thirdPart[thirdTable.selectedRow]
            }
            
            contactField.becomeFirstResponder()
            thirdTable.deselectAll(self)
        }

    }
    
}
