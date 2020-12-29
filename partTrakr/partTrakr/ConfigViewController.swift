//
//  ConfigViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/17/20.
//
import Foundation
import Cocoa

class ConfigViewController: NSViewController, NSTableViewDelegate,NSTableViewDataSource, NSWindowDelegate {
    var spaceIndent = "t"
    
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var thirdScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var thirdTable: NSTableView!
    
    @IBOutlet weak var configTypeField: NSTextField!
    @IBOutlet weak var configField: NSTextField!
    @IBOutlet weak var configTypeLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        firstTable.delegate = self
        firstTable.dataSource = self
        secondTable.delegate = self
        secondTable.dataSource = self
        thirdTable.delegate = self
        thirdTable.dataSource = self

        firstTable?.layer?.cornerRadius = 8.0
        firstTable?.layer?.masksToBounds = true
        secondTable.layer?.cornerRadius = 8.0
        secondTable.layer?.masksToBounds = true
        thirdTable.layer?.cornerRadius = 8.0
        thirdTable.layer?.masksToBounds = true

        configField.layer?.cornerRadius = 8.0
        configField.layer?.masksToBounds = true
        configTypeField.layer?.cornerRadius = 8.0
        configTypeField.layer?.masksToBounds = true

        var res = p.exec(statement: "select config from mecb_config order by config;")
        var num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()
        thirdPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
        
        res.clear()

        res = p.exec(statement: "select config_type from mecb_config_type order by config_type;")
        num = res.numTuples()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            secondPart.append(c1)
        }
        
        res.clear()

        firstTable?.reloadData()
        resizedColumn(view: firstTable!)
        secondTable.reloadData()
        resizedColumn(view: secondTable)
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.4, green: 0.5, blue: 0.5, alpha: 1.0)
        self.view.window?.title = "Configurations"
        let theWidth = self.view.bounds.width
        let theHeight = self.view.bounds.height
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1300, height: 750), display: true)
        self.view.window?.minSize = NSSize(width: 1300, height: 750)
        self.view.window?.maxSize = NSSize(width: 1300, height: 750)
        self.view.window?.center()
        configField.becomeFirstResponder()
        let firstHeader = tableView(firstTable!, scrollView: firstScroll, labelName: "Configurations", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(firstHeader)

        let secondHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Config Types", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(secondHeader)
        
        let thirdHeader = tableView(thirdTable, scrollView: thirdScroll, labelName: "Config List", viewForHeaderInSection: 1)
            thirdTable.headerView?.addSubview(thirdHeader)

    }

    @IBAction func clearEntryFieldButton(_ sender: NSButton) {
        configField.stringValue = ""
        configTypeField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
    }

    @IBAction func deleteButton(_ sender: NSButton) {
        doProc(proc_name: "call api_config_del('\(configField.stringValue)') ")
        configField.stringValue = ""
        configTypeField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        
        let res = p.exec(statement: "select config from mecb_config order by config;")
        let num = res.numTuples()
        firstPart.removeAll()
        
        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
        
        res.clear()

        firstTable.reloadData()
    }
    
    @IBAction func removeButton(_ sender: NSButton) {
        doProc(proc_name: "call api_config_rem('\(configField.stringValue)') ")
        configField.stringValue = ""
        configTypeField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        
        let res = p.exec(statement: "select config from mecb_config order by config;")
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
        doProc(proc_name: "call api_config_upd('\(configTypeField.stringValue)', '\(configField.stringValue)') ")
        configField.stringValue = ""
        configTypeField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        
        let res = p.exec(statement: "select config from mecb_config order by config;")
        let num = res.numTuples()
        firstPart.removeAll()
        
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
        
        res.clear()

        firstTable.reloadData()

    }
    
    @IBAction func insertButton(_ sender: NSButton) {
        doProc(proc_name: "call api_config_ins('\(configField.stringValue)', '\(configTypeField.stringValue)') ")
        configField.stringValue = ""
        configTypeField.stringValue = ""
        thirdPart.removeAll()
        thirdTable.reloadData()
        resizedColumn(view: thirdTable)
        
        let res = p.exec(statement: "select config from mecb_config order by config;")
        let num = res.numTuples()
        firstPart.removeAll()
        
        for x in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
        
        res.clear()

        firstTable.reloadData()

    }
    
    @IBAction func closeButton(_ sender: NSButton) {
        self.view.window?.close()
    }

    @IBAction func arrowIndentButton(_ sender: NSButton) {
        
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                    ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else if tableView == secondTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        } else {
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigCell3"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: thirdPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }
    
    var fiddlyBits = false
    
    // We are using the configuration type field to handle config types and
    // parent configurations.  This is the reason for fiddlyBits.
    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSObject == firstTable {

            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                
                if !fiddlyBits {
                    configField.stringValue = ""
                    configTypeField.stringValue = ""
                    fiddlyBits = true
                } else {
                    configTypeField.stringValue = ""
                    fiddlyBits = false
                }
                
                if configField.stringValue.count == 0 {
                    configField.stringValue = firstPart[firstTable.selectedRow]
                    configTypeLabel.stringValue = "Configuration Type"
                    configTypeField.stringValue = ""
                    
                    let theQuery = configVC_configType(config: configField.stringValue)
                    let res = p.exec(statement: theQuery)
                    let num = res.numTuples()
                        
                    for i in 0..<num {
                        guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                        configTypeField.stringValue = c1
                    }
                        
                    res.clear()

                    thirdPart = getConfigList(config_name: configField.stringValue, ind_type: spaceIndent)!
                } else if configTypeField.stringValue.count == 0 {
                    configTypeField.stringValue = firstPart[firstTable.selectedRow]
                    thirdPart.removeAll()
                    configTypeLabel.stringValue = "Parent Config"
                    fiddlyBits = false
                } else {
                    configField.stringValue = firstPart[firstTable.selectedRow]
                    configTypeField.stringValue = ""
                    configTypeLabel.stringValue = "Configuration Type"
                    thirdPart = getConfigList(config_name: configField.stringValue, ind_type: spaceIndent)!
                }

                thirdTable.reloadData()
                resizedColumn(view: thirdTable)
            }

            firstTable.deselectAll(self)
        } else if notification.object as? NSObject == secondTable {
            
            if secondTable.selectedRow >= 0 {
                clickPlayer.play()
                configTypeLabel.stringValue = "Configuration Type"
                configTypeField.stringValue = secondPart[secondTable.selectedRow]
                
                let res = p.exec(statement: partVC_configType(part_type: configTypeField.stringValue))
                
                let num = res.numTuples()
                
                for i in 0..<num {
                    guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
                    thirdPart.append(c1)
                }
                 
                res.clear()
                thirdTable.reloadData()
            }
            
            secondTable.deselectAll(self)
        }
        
        thirdTable.deselectAll(self)
    }

}
