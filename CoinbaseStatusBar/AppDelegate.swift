//
//  AppDelegate.swift
//  CoinbaseStatusBar
//
//  Created by redmond.martin@gmail.com on 2/21/15.
//  Copyright (c) 2015 redmond.martin@gmail.com All rights reserved.
//

import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSStreamDelegate, NSApplicationDelegate {
    
    let serverHost:String = "chat52.com"
    let serverPort:Int = 5898
    
    @IBOutlet weak var window: NSWindow!
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    
    override func awakeFromNib() {
        statusBarItem = statusBar.statusItemWithLength(-1)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        self.window!.orderOut(self)
        connect2server ( serverHost, port: serverPort )
        send("login")
    }
    
    func doDisplay ( msg: String ) {
        dispatch_async(dispatch_get_main_queue()) {
            self.statusBarItem.title = msg
        }
    }
    
    let bufferSize = 1024
    var buffer = Array<UInt8>(count: 1024, repeatedValue: 0)
    func handleRead(s: NSInputStream) {
        let bytesRead = s.read(&buffer, maxLength: bufferSize)
        if bytesRead > 0 {
            var output:String = NSString(bytes: &buffer, length: bytesRead, encoding: NSUTF8StringEncoding)!
            var lines = split ( output) {$0 == "\n"}
            var vals = split ( lines.last! ) {$0 == " "}
            self.doDisplay(vals.first!)
        }
    }
    
    var inputStream:NSInputStream?
    var outputStream:NSOutputStream?

    func stream(s: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.HasBytesAvailable:
            if let i = inputStream {
                handleRead(i)
            }
        case NSStreamEvent.ErrorOccurred:
            doDisplay ( "Network Error")
            netCloseAndReconnect()
        case NSStreamEvent.EndEncountered:
            doDisplay ("Server Error")
            netCloseAndReconnect()
        default:
            break;
        }
    }
    
    func send(msg:String) {
        if let o = outputStream {
            if o.hasSpaceAvailable {
                dispatch_async(dispatch_get_main_queue()) {
                    o.write(msg, maxLength: countElements(msg))
                    return
                }
            }
        }
    }
    
    func connect2server ( host: String, port: Int ) {
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        netOpen()
        self.doDisplay("Connecting")
    }

    func netOpen () {
        inputStream?.delegate = self
        outputStream?.delegate = self
        inputStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream?.open()
        outputStream?.open()
    }

    var reconnecting = false
    func netCloseAndReconnect () {
        inputStream?.close()
        outputStream?.close()
        inputStream?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        if reconnecting {
            return
        }
        reconnecting = true
        let delta = NSEC_PER_SEC * 2
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delta) ),
            dispatch_get_main_queue()) {
                self.connect2server(self.serverHost, port: self.serverPort)
                self.reconnecting = false
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

