//
//  AppDelegate.swift
//  CastCommander

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, OCDeviceManagerDelegate, OCDeviceScannerListener {
                            
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var devicePopupButton: NSPopUpButton!
    @IBOutlet weak var connectButton: NSButton!
    
    var controlWindow: ControlWindowController?
    
    var devices: NSMutableArray
    var deviceScanner: OCDeviceScanner?
    var deviceManager: OCDeviceManager?
    
    override init()  {
        devices = NSMutableArray()
        deviceManager = OCDeviceManager()
        
        super.init()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        deviceScanner = OCDeviceScanner()
        deviceScanner?.addListener(self)
        deviceScanner?.startScan()
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    //MARK: - UI
    
    @IBAction func clickButton(sender : NSButton) {
        NSLog("clickButton")
        
        let selectedDevice = devices.objectAtIndex(devicePopupButton.indexOfSelectedItem) as OCDevice;
        controlWindow = ControlWindowController(window: nil)
        if (controlWindow != nil) {
            controlWindow!.device = selectedDevice
            controlWindow?.showWindow(self)
        }
        window.orderOut(self)
    }
    
    //MARK: - Private
    func refreshDeviceList() {
        devicePopupButton.removeAllItems()
        for device in devices {
            devicePopupButton.addItemWithTitle(device.friendlyName)
        }
    }
}

// MARK: - OCDeviceScannerListener
extension AppDelegate: OCDeviceScannerListener {
    func deviceDidComeOnline(device: OCDevice!) {
        devices.addObject(device)
        refreshDeviceList()
    }
    
    func deviceDidGoOffline(device: OCDevice!) {
        devices.removeObject(device)
    }
}