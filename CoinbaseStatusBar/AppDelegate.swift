//
//  AppDelegate.swift
//  CoinbaseStatusBar
//
//  Created by mr on 2/21/15.
//  Copyright (c) 2015 mr. All rights reserved.
//

import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    override func awakeFromNib() {
        println ( "awake")
        // theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times!"
        
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        // statusBarItem.menu = menu
        //        statusBarItem.title = "Presses"
        
        //Add menuItem to menu
        menuItem.title = "Clicked"
        menuItem.action = Selector("setWindowVisible:")
        menuItem.keyEquivalent = ""
        // menu.addItem(menuItem)
    }
    
    //    func applicationDidFinishLaunching(aNotification: NSNotification?) {
    //        statusBarItem.title = "adfl"
    //        self.window!.orderOut(self)
    //    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        self.window!.orderOut(self)
        connect2server ( "chat52.com", port: 5898 )
        send("login")
    }
    
    func doDisplay ( msg: String ) {
        dispatch_async(dispatch_get_main_queue()) {
            self.statusBarItem.title = msg
        }
    }

    let netQueue = dispatch_queue_create("tcp-client-queue", DISPATCH_QUEUE_SERIAL)
    
    func connect2server ( host: String, port: Int ) {
        var inputStream:NSInputStream?
        var outputStream:NSOutputStream?
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        
        if inputStream == nil || outputStream == nil {
            doDisplay("Error connecting")
            return
        }
        
        var input = inputStream!
        dispatch_async(netQueue) {
            input.open()
            let bufferSize = 1024
            var buffer = Array<UInt8>(count: bufferSize, repeatedValue: 0)
            while (true) {
                let bytesRead = input.read(&buffer, maxLength: bufferSize)
                if bytesRead >= 0 {
                    var output:String = NSString(bytes: &buffer, length: bytesRead, encoding: NSUTF8StringEncoding)!
                    var lines = split ( output) {$0 == "\n"}
                    var vals = split ( lines.last! ) {$0 == " "}
                    self.doDisplay(vals.first!)
                    println ( vals )
                } else {
                    self.doDisplay ( "Connection Lost")
                    return
                }
            }
        }
        output = outputStream!
        output?.open()
        self.doDisplay("Connecting")
    }

    var output: NSOutputStream?

    func send (msg: String) {
        dispatch_async(netQueue) {
            let data = msg.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            if let out = self.output {
                out.write (UnsafePointer(data.bytes), maxLength:data.length )
            }
            println ( "sending ", msg )
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

