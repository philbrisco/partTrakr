//
//  ContactDetailViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/26/20.
//

import Cocoa

class ContactDetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var sthirdScroll: NSScrollView!
    
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    
    @IBOutlet weak var firstField: NSTextField!
    @IBOutlet weak var secondField: NSTextField!
    @IBOutlet weak var thirdField: NSTextField!
    
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
        
        firstPart.removeAll()
        secondPart.removeAll()
        thirdPart.removeAll()
        
        firstField.stringValue = ""
        secondField.stringValue = ""
        thirdField.stringValue = ""
        
        var res = p.exec(statement: "select contact from mecb_contact order by contact")
        var num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        res = p.exec(statement: "select contact_type from mecb_contact_det_type order by contact_type_id")
        num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            thirdPart.append(c1)
        }

        res.close()
        
        firstTable.reloadData()
        resizedColumn(view: firstTable)
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.3, green: 0.0, blue: 0.3, alpha: 1.0)
        self.view.window?.title = "Contact Details"
        let theWidth = self.view.bounds.width/2
        let theHeight = self.view.bounds.height/2
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 918, height: 720), display: true)
        self.view.window?.minSize = NSSize(width: 918, height: 720)
        self.view.window?.maxSize = NSSize(width: 918, height: 720)
        self.view.window?.center()

        firstField.becomeFirstResponder()

        let contactHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Contacts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(contactHeader)
        
        let typesHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Contact Details", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(typesHeader)
        
        let allTypesHeader = tableView(thirdTable, scrollView: secondScroll, labelName: "All Contact Details", viewForHeaderInSection: 1)
        thirdTable.headerView?.addSubview(allTypesHeader)
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_det_ins('\(firstField.stringValue)','\(secondField.stringValue)','\(thirdField.stringValue)')")
        
        firstField.stringValue = ""
        secondField.stringValue = ""
        thirdField.stringValue = ""
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_det_del('\(firstField.stringValue)', '\(secondField.stringValue)')")
        secondPart.removeAll()
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        
        firstField.becomeFirstResponder()
        firstField.stringValue = ""
        secondField.stringValue = ""
        thirdField.stringValue = ""
    }
    
    @IBAction func clerFieldsButton(_ sender: NSButton) {
        firstField.stringValue = ""
        secondField.stringValue = ""
        thirdField.stringValue = ""
        firstField.becomeFirstResponder()
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        firstField.stringValue = ""
        secondField.stringValue = ""
        thirdField.stringValue = ""
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactDetCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        case secondTable:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactDetCell2"), owner: self) {
 
                let start_one = secondPart[row].startIndex
                guard let end_one = secondPart[row].firstIndex(of: ":") else {return nil}
                let string_length = secondPart[row].distance(from: start_one, to: end_one)
                
                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowTextAlt(targetString: secondPart[row], doRainbow: true, attributes: nil, size: 18, length: string_length)

                return cellView
            }

        default:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactDetCell3"), owner: self) {
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
                firstField.stringValue = firstPart[firstTable.selectedRow]
            
                secondPart.removeAll()
                let res = p.exec(statement: "\(contactDetVC_det(contact: firstField.stringValue))")
                let num = res.numTuples()
            
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    guard let c2 = res.getFieldString(tupleIndex: i, fieldIndex: 1) else {return}
                    secondPart.append("\(c1): \(c2)")
                }
        
                secondTable.reloadData()
                resizedColumn(view: secondTable)
            }
            
            secondField.stringValue = ""
            firstTable.deselectAll(self)
            secondField.becomeFirstResponder()

        case secondTable:
            secondTable.deselectAll(self)
        default:

            if thirdTable.selectedRow >= 0 {
                clickPlayer.play()
                secondField.stringValue = thirdPart[thirdTable.selectedRow]
            }
            
            thirdField.becomeFirstResponder()
            thirdTable.deselectAll(self)
        }

    }
}
