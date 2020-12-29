//
//  PartListViewController.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/11/20.
//

import Foundation
import Cocoa

class PartListViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    var spaceIndent = "t"
    
    fileprivate enum CellIdentifiers {
        static let PartListCell = "PartListCellID"
        static let DateCell = "DateCellID"
        static let SizeCell = "SizeCellID"
      }
    
    @IBOutlet weak var firstScroll: NSScrollView!
    @IBOutlet weak var firstTable: NSTableView!
    @IBOutlet weak var secondTable: NSTableView!
    @IBOutlet weak var secondScroll: NSScrollView!
    @IBOutlet weak var partNameField: NSTextField!
    
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

        partNameField.layer?.cornerRadius = 8.0
        partNameField.layer?.masksToBounds = true

        let res = p.exec(statement: "select part from mecb_part where part_id = parent_part_id")
        let num = res.numTuples()
        firstPart.removeAll()
        secondPart.removeAll()

        for i in 0..<num {
            guard let c1 = res.getFieldString(tupleIndex: i, fieldIndex: 0) else {return}
            firstPart.append(c1)
        }
    
        res.clear()
        firstTable.reloadData()
        secondTable.reloadData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.backgroundColor = NSColor.init(displayP3Red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0)
        self.view.window?.title = "Part List"
        let theWidth = self.view.bounds.width/4
        let theHeight = self.view.bounds.height/4
        self.view.window?.setFrame(NSRect(x: theWidth, y: theHeight, width: 1000, height: 750), display: true)
        self.view.window?.minSize = NSSize(width: 1000, height: 750)
        self.view.window?.maxSize = NSSize(width: 1000, height: 750)
        self.view.window?.center()

        partNameField.becomeFirstResponder()
        let partListHeader = tableView(secondTable, scrollView: secondScroll, labelName: "Part List", viewForHeaderInSection: 1)
        secondTable.headerView?.addSubview(partListHeader)
        
        let partNameHeader = tableView(firstTable, scrollView: firstScroll, labelName: "Top Level Part Names", viewForHeaderInSection: 1)
        firstTable.headerView?.addSubview(partNameHeader)
    }

    @IBAction func refreshButton(_ sender: Any) {
        secondPart = getPartList(part_name: partNameField.stringValue, ind_type: spaceIndent)!
        secondTable.reloadData()
        resizedColumn(view: secondTable)
    }
    
    @IBAction func closeButton(_ sender: Any) {
        self.view.window?.close()
    }

    @IBAction func arrowIndentCheck(_ sender: NSButtonCell) {
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

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartListCell"), owner: self) {
                let myAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18)
                    ]

                 (cellView as? NSTableCellView)?.textField?.attributedStringValue =
                    rainbowText(targetString: firstPart[row], doRainbow: false, attributes: myAttributes, size: 18)

                return cellView
            }
            
        } else {

            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PartListCell2"), owner: self) {
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
                partNameField.stringValue = firstPart[firstTable.selectedRow]
                secondPart = getPartList(part_name: partNameField.stringValue, ind_type: spaceIndent)!
                secondTable.reloadData()
                resizedColumn(view: secondTable)
                partNameField.becomeFirstResponder()
            }
            
        }
        
        secondTable.deselectAll(self)
        resizedColumn(view: secondTable)
        firstTable.deselectAll(self)
        resizedColumn(view: firstTable)
    }
    
}
