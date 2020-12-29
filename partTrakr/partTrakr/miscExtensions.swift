//
//  miscExtensions.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/11/20.
//

import Foundation
import Cocoa

extension NSView {
    func findViewController() -> NSViewController? {
        if let nextResponder = self.nextResponder as? ViewController {
            return nextResponder
        } else if let nextResponder = self.nextResponder as? NSView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// Resizes columns based on the length of the longest cell.
extension NSTableViewDelegate {
    func resizedColumn (view: NSTableView) {
        var longest:CGFloat = 0
        let column = view.tableColumns[0] as NSTableColumn

        for i in 0..<view.numberOfRows {
            let cell = view.dataSource?.tableView!(view, objectValueFor: column, row: i) as! String
            let myAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 18)]
            let attributedString = NSAttributedString(string: cell, attributes: myAttribute as [NSAttributedString.Key : Any])
            let width = CGFloat(attributedString.size().width)

            if longest < width {
                longest = width
            }

        }

        column.width = longest + 50
        view.reloadData()
    }
    
    // Since this is used by all the tableview classes to find the length of
    // the longest cell for a table, I put it here once rather tham put it in
    // each view controller.
    func tableView(_ tableView: NSTableView, scrollView: NSScrollView, labelName: String, viewForHeaderInSection section: Int) -> NSView {
        let headerView = NSView.init(frame: CGRect.init(x: 0, y: 0, width: scrollView.frame.width - 10, height: scrollView.frame.height - 5))
        let label = centeredTextFieldCell()
        let labelFrame = NSTextField()

        labelFrame.frame = CGRect.init(x: 5, y: 5, width: headerView.frame.width - 10, height: headerView.frame.height - 5)
        let myAttribute: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.font: NSFont(name: "Charter Black Italic",  size: 18) as Any,
                    NSAttributedString.Key.foregroundColor: NSColor.systemOrange]
        let attributedString = NSAttributedString(string: labelName, attributes: myAttribute as [NSAttributedString.Key : Any])

        label.attributedStringValue = attributedString
        labelFrame.cell = label
        headerView.addSubview(labelFrame)
        return headerView
    }

    func numberOfSections(in tableView: NSTableView) -> Int {
       return tableView.numberOfColumns
   }


}

