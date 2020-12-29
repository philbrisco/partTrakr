//
//  ContactViewContrloller.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/25/20.
//

import Cocoa

class ContactViewController: NSViewController,NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var contactNameField: NSTextField!
    @IBOutlet weak var newContactNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        firstTable.delegate = self
        firstTable.dataSource = self
        
        firstTable.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        
        let res = p.exec(statement: "select contact from mecb_contact order by contact")
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
        
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.1, blue: 0.2, alpha: 1.0)
        contactNameField.layer?.backgroundColor = .clear
        contactNameField.backgroundColor = .clear
        self.view.window?.title = "Contacts"
        let theWidth = self.view.bounds.width/8
        let theHeight = self.view.bounds.height/8
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 577, height: 471), display: true)
        self.view.window?.minSize = NSSize(width: 577, height: 471)
        self.view.window?.maxSize = NSSize(width: 577, height: 471)
        contactNameField.becomeFirstResponder()
        
        let contactHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Contacts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(contactHeader)
    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_ins('\(contactNameField.stringValue)')")

        // Ensure there was no database error before appending to table.
        if p.errorMessage().count == 0 {
            firstPart.append(contactNameField.stringValue)
            firstPart.sort()
        }
        
        contactNameField.stringValue = ""
        newContactNameField.stringValue = ""
        firstTable.reloadData()
        resizedColumn(view: firstTable)
    }
    
    @IBAction func updateButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_upd('\(contactNameField.stringValue)','\(newContactNameField.stringValue)')")
        
        let res = p.exec(statement: "select contact from mecb_contact order by contact")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        contactNameField.stringValue = ""
        newContactNameField.stringValue = ""
        firstTable.reloadData()
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_contact_del('\(contactNameField.stringValue)')")
        
        let res = p.exec(statement: "select contact from mecb_contact order by contact")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        contactNameField.stringValue = ""
        newContactNameField.stringValue = ""
        firstTable.reloadData()    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        contactNameField.stringValue = ""
        newContactNameField.stringValue = ""
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ContactCell"), owner: self) {
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
                contactNameField.stringValue = firstPart[firstTable.selectedRow]
            }
            
            newContactNameField.stringValue = ""
            firstTable.deselectAll(self)
            newContactNameField.becomeFirstResponder()
        }
        
    }
}

