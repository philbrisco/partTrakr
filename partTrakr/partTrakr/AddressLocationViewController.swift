//
//  AddressLocationViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/25/20.
//

import Foundation
import Cocoa

class AddressLocationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var firstTable: NSTableView!
    
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var locationField: NSTextField!
    @IBOutlet weak var addressField: NSTextField!
    
    
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
        
        let res = p.exec(statement: "select loc from mecb_loc order by loc")
        let num = res.numTuples()
        
        firstPart.removeAll()
        secondPart.removeAll()
        locationField.stringValue = ""
        addressField.stringValue = ""
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        firstTable.reloadData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        self.view.window?.title = "Address Locations"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 600, height: 500), display: true)
        self.view.window?.minSize = NSSize(width: 600, height: 500)
        self.view.window?.maxSize = NSSize(width: 600, height: 500)
        self.view.window?.center()
        locationField.becomeFirstResponder()

        let locHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Locations", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(locHeader)
        
        let addressHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Addresses", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(addressHeader)

    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_addr_loc_ins('\(locationField.stringValue)','\(addressField.stringValue)')")
        locationField.stringValue = ""
        addressField.stringValue = ""
        locationField.stringValue = ""
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        locationField.becomeFirstResponder()
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_addr_loc_del('\(locationField.stringValue)','\(addressField.stringValue)')")
        
        // If a single row of the address is selected, only delete it.
        if addressField.stringValue.count > 0 {
            secondPart.remove(at: secondTable.selectedRow)
        } else {
            secondPart.removeAll()
            locationField.stringValue = ""
        }

        secondTable.reloadData()
        resizedColumn(view: secondTable)
        
        locationField.becomeFirstResponder()
        addressField.stringValue = ""
    }
    
    @IBAction func clearFieldsButton(_ sender: NSButton) {
        locationField.stringValue = ""
        addressField.stringValue = ""
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        locationField.becomeFirstResponder()
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        locationField.stringValue = ""
        addressField.stringValue = ""
        firstPart.removeAll()
        secondPart.removeAll()
        self.view.window?.close()
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
        
        switch tableView {
        case firstTable:

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddressLocCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        default:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddressLocCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

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
                locationField.stringValue = firstPart[firstTable.selectedRow]
            
                secondPart.removeAll()
                let res = p.exec(statement: "\(addrLocVC_addr(location: locationField.stringValue))")
                let num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    secondPart.append(c1)
                }
        
                secondTable.reloadData()
                resizedColumn(view: secondTable)
            }
            
            addressField.stringValue = ""
            firstTable.deselectAll(self)
            addressField.becomeFirstResponder()

        default:
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                addressField.stringValue = secondPart[secondTable.selectedRow]
            }
            
            locationField.becomeFirstResponder()
        }

    }
}
