//
//  miscClasses.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/15/20.
//
import EventKit
import Cocoa

class centeredTextFieldCell: NSTextFieldCell {
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var titleRect = super.titleRect(forBounds: rect)
        let minimumWidth = self.cellSize(forBounds: rect).width
        let minimumHeight  = self.cellSize(forBounds: rect).height

        titleRect.origin.x += (titleRect.width - minimumWidth)/2
//        titleRect.origin.y -= (titleRect.height - minimumHeight)/2 + 10
        titleRect.origin.y += -20
        titleRect.size.height = minimumHeight + 22
        
        return titleRect
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }
    
}

class attHeaderCell: NSTableHeaderCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
        NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.8, alpha: 0.3).set()
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        attributedStringValue = NSAttributedString(string: stringValue, attributes: [NSAttributedString.Key.font: NSFont(name: "Charter Black Italic", size: 18)!])
        let offSetFrame = NSOffsetRect(drawingRect(forBounds: cellFrame), 4, 0)
        super.drawInterior(withFrame: offSetFrame, in: controlView)
    }
}

public class GlobalEventMonitor {
    
    private var monitor: AnyObject?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> ()

    public init (mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
 
    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
    
    public func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject?
     }
    
}

public class LocalEventMonitor {
    
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> NSEvent?
    
    public init (mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
    
    public func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
    }
}
