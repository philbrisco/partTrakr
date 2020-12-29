//
//  ConfigTypeViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/28/20.
//

import Cocoa

class ConfigTypeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    
    @IBOutlet weak var firstField: NSTextField!
    @IBOutlet weak var secondField: NSTextField!
    
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
        firstField.layer?.cornerRadius = 8.0
        firstTable.layer?.masksToBounds = true
        secondTable.layer?.cornerRadius = 8.0
        secondTable.layer?.masksToBounds = true
        
        firstPart.removeAll()
        secondPart.removeAll()
        
        var res = p.exec(statement: "select config_type from mecb_config_type order by config_type")
        var num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()

        res = p.exec(statement: "select part_type from mecb_part_type order by part_type")
        num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }

        res.clear()

        firstTable.reloadData()
        resizedColumn(view: firstTable)
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        firstField.stringValue = ""
        secondField.stringValue = ""
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.5, green: 0.1, blue: 0.5, alpha: 1.0)
        self.view.window?.title = "Configuration Type"
        let theWidth = self.view.bounds.width
        let theHeight = self.view.bounds.height
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 700, height: 600), display: true)
        self.view.window?.minSize = NSSize(width: 700, height: 600)
        self.view.window?.maxSize = NSSize(width: 700, height: 600)
        self.view.window?.center()

        let configTypeHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Configuration Type", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(configTypeHeader)
        
        let partTypeHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Part Type", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(partTypeHeader)

    }

    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_config_type_ins('\(firstField.stringValue)','\(secondField.stringValue)')")
        firstPart.removeAll()
        
        let res = p.exec(statement: "select config_type from mecb_config_type order by config_type")
        let num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        firstTable.reloadData()
        resizedColumn(view: firstTable)
        firstField.stringValue = ""
        secondField.stringValue = ""
    }
    
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_config_type_del('\(firstField.stringValue)')")
        firstPart.removeAll()
        
        let res = p.exec(statement: "select config_type from mecb_config_type order by config_type")
        let num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }

        res.clear()
        
        firstTable.reloadData()
        resizedColumn(view: firstTable)
        firstField.stringValue = ""
        secondField.stringValue = ""
    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        firstField.stringValue = ""
        secondField.stringValue = ""
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigTypeCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                ]

                (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        default:
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigTypeCell2"), owner: self) {
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
                firstField.stringValue = firstPart[firstTable.selectedRow]
            
                let res = p.exec(statement: "\(configTypeVC_partType(configType: firstField.stringValue))")
                let num = res.numTuples()
                print ("gothereaaa \(firstField.stringValue)")
                print ("gotherebbb \(configTypeVC_partType(configType: firstField.stringValue))")
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    secondField.stringValue = c1
                    print ("gothere  '\(c1)'")
                }
        
            }
            
            firstTable.deselectAll(self)
            secondField.becomeFirstResponder()

        default:
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                secondField.stringValue = secondPart[secondTable.selectedRow]
            }
            
            secondTable.deselectAll(self)
            firstField.becomeFirstResponder()
        }

    }
}
