//
//  swiftyVars.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/10/20.
//

import Foundation
import PerfectPostgreSQL
import Cocoa

var eventHandler: GlobalEventMonitor?
var locEventHandler: LocalEventMonitor?
var getInfoFlag:Bool = false
var p = PGConnection()

var firstPart = [String]()
var secondPart = [String]()
var thirdPart = [String]()

var winController = NSWindowController()
var splashController: NSWindowController?
//var controller = ViewController()

enum procName {
    case db_name
}

var procType = procName.db_name
