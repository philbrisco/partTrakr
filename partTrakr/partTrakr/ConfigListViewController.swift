//
//  ConfigListViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/16/20.
//

import Foundation
import Cocoa

class ConfigListViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var spaceIndent = "t"

    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var configNameField: NSTextField!

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

            configNameField.layer?.cornerRadius = 8.0
            configNameField.layer?.masksToBounds = true

            let res = p.exec(statement: "select config from mecb_config where config_id = parent_config_id")
            let num = res.numTuples()
            firstPart.removeAll()
            secondPart.removeAll()

            for x in 0..<num {
                guard let c1 = res.getFieldString(tupleIndex: x, fieldIndex: 0) else {return}
                firstPart.append(c1)
            }
        

        res.clear()
        firstTable.reloadData()
        secondTable.reloadData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0)
        self.view.window?.title = "Configuration List"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1000, height: 750), display: true)
        self.view.window?.minSize = NSSize(width: 1000, height: 750)
        self.view.window?.maxSize = NSSize(width: 1000, height: 750)
        self.view.window?.center()

        configNameField.becomeFirstResponder()
            let configListHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Configuration List", viewForHeaderInSection: 1)

            secondTable.headerView?.addSubview(configListHeader)
            let configNameHeader = tableView(secondTable, scrollView: firstScroll, labelName: "Top Level Config Names", viewForHeaderInSection: 1)
            firstTable.headerView?.addSubview(configNameHeader)
        }

        @IBAction func refreshButton(_ sender: Any) {
            secondPart = getConfigList(config_name: configNameField.stringValue, ind_type: spaceIndent)!
            secondTable.reloadData()
            resizedColumn(view: secondTable)
        }
        
        @IBAction func closeButton(_ sender: Any) {
            self.view.window?.close()
        }

        @IBAction func arrowIndenter(_ sender: NSButton) {
            switch sender.state {
            case .on:
                spaceIndent = "f"
            default:
                spaceIndent = "t"
            }
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            
            if tableView == firstTable {
                return firstPart.count
            } else {
                return secondPart.count
            }
        }

        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            
            if tableView == firstTable {
                return firstPart[row]
            } else {
                return secondPart[row]
            }
        }
        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == firstTable {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigListCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                    ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConfigListCell2"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                 ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue = rainbowText(targetString: secondPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
          
        if notification.object as? NSObject == firstTable {

            if firstTable.selectedRow >= 0 {
                clickPlayer.play()
                configNameField.stringValue = firstPart[firstTable.selectedRow]
                secondPart = getConfigList(config_name: configNameField.stringValue, ind_type: spaceIndent)!
                secondTable.reloadData()
                configNameField.becomeFirstResponder()
            }
        }
            
        secondTable.deselectAll(self)
        resizedColumn(view: secondTable)
        secondTable.deselectAll(self)
        firstTable.deselectAll(self)
    }
        
    }
