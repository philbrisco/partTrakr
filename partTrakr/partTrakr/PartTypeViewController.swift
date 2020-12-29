//
//  PartTypeViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/28/20.
//

import Cocoa

class PartTypeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var firstField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        firstTable.delegate = self
        firstTable.dataSource = self
        
        firstTable.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        firstField.layer?.cornerRadius = 8.0
        firstField.layer?.masksToBounds = true
        
        firstPart.removeAll()
        firstField.stringValue = ""
        
        let res = p.exec(statement: "select part_type from mecb_part_type order by part_type")
        let num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        firstTable.reloadData()
        resizedColumn(view: firstTable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.7, blue: 0.5, alpha: 1.0)
        self.view.window?.title = "Part Type"
        let theWidth = self.view.bounds.width
        let theHeight = self.view.bounds.height
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 500, height: 600), display: true)
        self.view.window?.minSize = NSSize(width: 500, height: 600)
        self.view.window?.maxSize = NSSize(width: 500, height: 600)
        self.view.window?.center()
        
        let partTypeHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Part Types", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(partTypeHeader)
        
        firstField.becomeFirstResponder()
    }

    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_type_ins('\(firstField.stringValue)')")
        
        // Ensure there was no error before updating the table.
        if p.errorMessage().count == 0 {
            firstPart.append(firstField.stringValue)
            firstPart.sort()
        }
        
        firstField.stringValue = ""
        firstTable.reloadData()
        resizedColumn(view: firstTable)    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_type_del('\(firstField.stringValue)')")
        
        let res = p.exec(statement: "select part_type from mecb_part_type order by part_type")
        let num = res.numTuples()
        
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()
        
        firstField.stringValue = ""
        firstTable.reloadData()
        resizedColumn(view: firstTable)
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        firstField.stringValue = ""
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartTypeCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        }
        
        firstField.becomeFirstResponder()
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {

            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                firstField.stringValue = firstPart[firstTable.selectedRow]
            }
            
            firstTable.deselectAll(self)
        }
        
    }
}

