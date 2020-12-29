//
//  PartViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/18/20.
//

import Foundation
import Cocoa

class PartViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    private var spaceIndent = "t"
            
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var thirdScroll: NSScrollView!
    @IBOutlet weak var partTypeLabel: NSTextField!
    @IBOutlet weak var partNameField: NSTextField!
    @IBOutlet weak var partTypeNameField: NSTextField!
    @IBOutlet weak var configTypeNameField: NSTextField!
    @IBOutlet weak var configTypeLabel: NSTextFieldCell!
    
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    
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

        partNameField.layer?.cornerRadius = 8.0
        partNameField.layer?.masksToBounds = true
        partTypeNameField.layer?.cornerRadius = 8.0
        partTypeNameField.layer?.masksToBounds = true
        configTypeNameField.layer?.cornerRadius = 8.0
        configTypeNameField.layer?.masksToBounds = true

        var res = p.exec(statement: "select part from mecb_part order by part;")
        var num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()
        thirdPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        res = p.exec(statement: "select part_type from mecb_part_type order by part_type;")
        num = res.numTuples()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }
            
        res.clear()

        firstTable.reloadData()
        resizedColumn(view: firstTable)
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.6, green: 0.6, blue: 0.4, alpha: 1.0)
        configTypeNameField.layer?.backgroundColor = .clear
        configTypeNameField.backgroundColor = .clear
        configTypeLabel.stringValue = ""
        let theWidth = self.view.bounds.width/16
        let theHeight = self.view.bounds.height/16
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1300, height: 750), display: true)
        self.view.window?.minSize = NSSize(width: 1300, height: 750)
        self.view.window?.maxSize = NSSize(width: 1300, height: 750)
        self.view.window?.title = "Parts"
        partNameField.becomeFirstResponder()
        let partHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Parts", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(partHeader)

        let partTypeHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Part Types", viewForHeaderInSection: 1)
            secondTable.headerView?.addSubview(partTypeHeader)
            
        let partListHeader = tableView(thirdTable, scrollView: thirdScroll, labelName: "Part List", viewForHeaderInSection: 1)
            thirdTable.headerView?.addSubview(partListHeader)

    }

    @IBAction func clearEntryFieldButton(_ sender: NSButton) {
        partNameField.stringValue = ""
        partTypeNameField.stringValue = ""
        configTypeNameField.stringValue = ""
        configTypeLabel.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }
        
    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_del('\(partNameField.stringValue)') ")
        partNameField.stringValue = ""
        partTypeNameField.stringValue = ""
        configTypeNameField.stringValue = ""
        configTypeLabel.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
            
        let res = p.exec(statement: "select part from mecb_part order by part;")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        firstTable.reloadData()
    }
        
    @IBAction func removeButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_rem('\(partNameField.stringValue)') ")
        partNameField.stringValue = ""
        partTypeNameField.stringValue = ""
        configTypeNameField.stringValue = ""
        configTypeLabel.stringValue = ""
        
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
            
        let res = p.exec(statement: "select part from mecb_part order by part;")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        firstTable.reloadData()
    }
        
    @IBAction func updateButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_upd('\(partTypeNameField.stringValue)', '\(partNameField.stringValue)') ")
        partNameField.stringValue = ""
        partTypeNameField.stringValue = ""
        configTypeNameField.stringValue = ""
        configTypeLabel.stringValue = ""
        
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
            
        let res = p.exec(statement: "select part from mecb_part order by part;")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        firstTable.reloadData()
    }
        
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_part_ins('\(partNameField.stringValue)', '\(partTypeNameField.stringValue)') ")
        partNameField.stringValue = ""
        partTypeNameField.stringValue = ""
        configTypeNameField.stringValue = ""
        configTypeLabel.stringValue = ""
        
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
            
        let res = p.exec(statement: "select part from mecb_part order by part;")
        let num = res.numTuples()
        firstPart.removeAll()
            
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
            
        res.clear()

        firstTable.reloadData()
    }

    @IBAction func closeButton(_ sender: Any) {
        self.view.window?.close()
    }

    @IBAction func arrowIndentCheck(_ sender: NSButton) {
            
        switch sender.state {
            case .on:
                spaceIndent = "f"
            default:
                spaceIndent = "t"
        }
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
        
        if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                    ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else if tableView == secondTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        } else {
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartCell3"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: thirdPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }
    
    var fiddly_bits = false
    
    // We are using the part type field to also handle the parent part.
    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {
            
            if firstTable.selectedRow >= 0 {
                clickPlayer.play()

                if !fiddly_bits {
                    partNameField.stringValue = ""
                    partTypeNameField.stringValue = ""
                    configTypeNameField.stringValue = ""
                    configTypeLabel.stringValue = ""
                    fiddly_bits = true
                } else {
                    partTypeNameField.stringValue = ""
                    configTypeNameField.stringValue = ""
                    configTypeLabel.stringValue = ""
                    fiddly_bits = false
                }

                if partNameField.stringValue.count == 0 {
                    partNameField.stringValue = firstPart[firstTable.selectedRow]
                    partTypeLabel.stringValue = "Part Type"
                    partTypeNameField.stringValue = ""
                    configTypeNameField.stringValue = ""
                    configTypeLabel.stringValue = ""
                    
                    let theQuery = partVC_partType(part: partNameField.stringValue)
                    let res = p.exec(statement: theQuery)
                    let num = res.numTuples()
                        
                    for x in 0..<num {
                        guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                        partTypeNameField.stringValue = c1
                        guard let c2 = res.getFieldString(tupleIndex: x, fieldIndex: 1) else {return}
                        configTypeNameField.stringValue = c2
                        configTypeLabel.stringValue = "Configuration Type"
                    }
                        
                    res.clear()

                    thirdPart = getPartList(part_name: partNameField.stringValue, ind_type: spaceIndent)!
                } else if partTypeNameField.stringValue.count == 0 {
                    partTypeNameField.stringValue = firstPart[firstTable.selectedRow]
                    thirdPart.removeAll()
                    partTypeLabel.stringValue = "Parent Part"
                    configTypeNameField.stringValue = ""
                    configTypeLabel.stringValue = ""
                    fiddly_bits = false
                } else {
                    partNameField.stringValue = firstPart[firstTable.selectedRow]
                    partTypeNameField.stringValue = ""
                    configTypeNameField.stringValue = ""
                    configTypeLabel.stringValue = ""
                    partTypeLabel.stringValue = "Part Type"
                    thirdPart = getPartList(part_name: partNameField.stringValue, ind_type: spaceIndent)!
                }

                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
            }

            firstTable.deselectAll(self)
        } else if notification.object as? NSObject == secondTable {
                
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                partTypeLabel.stringValue = "Part Type"
                partTypeNameField.stringValue = ""
                //secondPart[secondTable.selectedRow]
                configTypeNameField.stringValue = ""
                configTypeLabel.stringValue = "Configuration Type"
                partTypeNameField.stringValue = secondPart[secondTable.selectedRow]
  
                let res = p.exec(statement: partVC_configType(part_type: partTypeNameField.stringValue))
                let num = res.numTuples()

                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    configTypeNameField.stringValue = c1
                }

                res.clear()
            }
                
            secondTable.deselectAll(self)
        } else {

        }
            
        thirdTable.deselectAll(self)
    }

}
