//
//  ControlWindowController.swift
//  CastCommander

import Cocoa
import Foundation

class ControlWindowController: NSWindowController, NSWindowDelegate, OCDeviceManagerDelegate, OCDefaultMediaReceiverControllerDelegate {
    
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var disconnectButton: NSButton!
    @IBOutlet weak var connectedToTextFieldCell: NSTextFieldCell!
    @IBOutlet weak var launchButton: NSButton!
    @IBOutlet weak var joinButton: NSButton!
    @IBOutlet weak var stopAppButton: NSButton!
    @IBOutlet weak var urlTextField: NSTextFieldCell!
    @IBOutlet weak var loadButton: NSButton!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var seekSlider: NSSlider!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var muteButton: NSButton!
    @IBOutlet weak var playbackCurrentTimeLabel: NSTextField!
    @IBOutlet weak var playbackCurrentTimeText: NSTextFieldCell!
    @IBOutlet weak var playbackDurationTimeLabel: NSTextField!
    @IBOutlet weak var playbackDurationTimeText: NSTextFieldCell!
    
    var deviceManager: OCDeviceManager?
    var device: OCDevice?
    var receiverApp: OCDefaultMediaReceiverController?
    
    var mediaDuration: Double?
    
    override init(window: NSWindow!) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var windowNibName : String! {
        return "ControlWindowController"
    }
    
    func prepareUI(forDevice device: OCDevice) {
        connectedToTextFieldCell.title = "Status: Ready to Connect"
        playbackCurrentTimeText.title = "00:00"
        playbackDurationTimeText.title = "00:00"
    }
    
    func enableLoadUI(enable: Bool) {
        connectButton.enabled = !enable
        disconnectButton.enabled = enable
        loadButton.enabled = enable
        muteButton.enabled = enable
    }
    
    func enableAppControlUI(enable: Bool) {
        launchButton.enabled = enable
        joinButton.enabled = enable
        stopAppButton.enabled = enable
    }
    
    func enablePlayUI(enable: Bool) {
        var buttons: NSArray = [playButton, pauseButton, stopButton, seekSlider];
        for button in buttons {
            if let b = button as? NSControl {
                b.enabled = enable
            }
        }
    }
    
    func updateUIForMediaStatus(mediaStatus: OCMediaStatus) {
        let currentPosition: Double = mediaStatus.streamPosition
        playbackCurrentTimeText.title = NSString(format: "%1.f:%02.f", currentPosition / 60, currentPosition % 60)
        playbackCurrentTimeLabel.setNeedsDisplay()
        
        let duration: Double = mediaStatus.mediaInformation.streamDuration
        playbackDurationTimeText.title = NSString(format: "%1.f:%02.f", duration / 60, duration % 60)
        playbackDurationTimeLabel.setNeedsDisplay()
        
        seekSlider.doubleValue = currentPosition / duration * 100
    }
    
    func returnToDeviceSelectionWindow() {
        window?.setIsVisible(false)
        
        NSApplication.sharedApplication().mainWindow?.setIsVisible(true)
    }
    
    @IBAction func performClick(sender: NSButton) {
        switch (sender) {
        case connectButton:
            connectToDevice(self.device)
        case disconnectButton:
            self.deviceManager?.disconnect()

            enableLoadUI(false)
            enableAppControlUI(false)
            enablePlayUI(false)
            returnToDeviceSelectionWindow()
        case launchButton:
            self.deviceManager?.launchApplication(kOCMediaDefaultReceiverApplicationID);
        case joinButton:
            self.deviceManager?.joinApplication(kOCMediaDefaultReceiverApplicationID)
        case stopAppButton:
            self.deviceManager?.stopApplication()
        case playButton:
            play()
        case pauseButton:
            pause()
        case stopButton:
            stop()
        case loadButton:
            if (countElements(self.urlTextField.title) > 0) {
                loadMedia(self.urlTextField.title)
            }
        case muteButton:
            if let currentlyMuted = self.receiverApp?.status.volumeMuted {
                mute(!currentlyMuted)
            }
        default:
            break
        }
    }
    
    @IBAction func sliderDidMove(sender: NSSlider) {
        assert(self.mediaDuration != nil)
        
        if (sender == seekSlider) {
            if (self.mediaDuration != nil) {
                let seekPercentage = self.seekSlider.doubleValue / 100.0;
                seekToPosition(seekPercentage * self.mediaDuration!)
            }
        } else if (sender == volumeSlider) {
            setVolume(self.volumeSlider.doubleValue / 100.0)
        }
    }
}

// MARK: CastDeviceController
extension ControlWindowController {
    func connectToDevice(device: OCDevice?) {
        self.deviceManager = OCDeviceManager(device: device, clientPackageName: "org.linuxguy.CastCommander")
        
        if ((self.deviceManager) != nil) {
            self.deviceManager!.delegate = self
            self.deviceManager!.connect()
        }
    }
    
    func seekToPosition(position: Double) {
        self.receiverApp?.seekToPosition(position)
    }
    
    func play() {
        self.receiverApp?.play()
    }
    
    func pause() {
        self.receiverApp?.pause()
    }
    
    func stop() {
        self.receiverApp?.stop()
    }
    
    func loadMedia(url: NSString) {
        self.receiverApp?.loadMediaFromURL(url)
    }
    
    func setVolume(value: Double) {
        self.receiverApp?.setVolume(value)
    }
    
    func mute(mute: Bool) {
        self.receiverApp?.mute(mute)
    }
}

extension ControlWindowController: OCDeviceManagerDelegate {
    func deviceManagerDidConnect(deviceManager: OCDeviceManager!) {
        self.receiverApp = OCDefaultMediaReceiverController(namespace: OpenCastNamespaceReceiver)
        self.receiverApp?.delegate = self
        
        deviceManager?.addChannel(self.receiverApp)
        
        enableLoadUI(true)
        enableAppControlUI(true)
        
        if let deviceName = self.device?.friendlyName {
            connectedToTextFieldCell.title = NSString(format: "Status: Connected to %@", deviceName)
        }
    }
    
    func deviceManager(deviceManager: OCDeviceManager!, didDisconnectWithError error: NSError!) {
        enablePlayUI(false)
        enableAppControlUI(false)
        enableLoadUI(false)
    }
}

extension ControlWindowController: OCDefaultMediaReceiverControllerDelegate {
    
    func applicationDidLaunchSuccessfully() {
        enableLoadUI(true)
        enablePlayUI(false)
    }
    
    func applicationFailedToLaunchWithError(reason: String!) {
        NSLog("Failed to launch: %@", reason)
    }
    
    func mediaDidLoadSuccessfully() {
        enableLoadUI(true)
        enablePlayUI(true)
    }
    
    func mediaReceiverController(controller: OCDefaultMediaReceiverController!, statusDidUpdate receiverStatus: OCMediaReceiverStatus!) {
        self.volumeSlider.floatValue = receiverStatus.volumeLevel * 100.0
        self.muteButton.state = receiverStatus.volumeMuted ? NSOnState : NSOffState
    }

    func mediaReceiverController(controller: OCDefaultMediaReceiverController!, mediaStatusDidUpdate mediaStatus: OCMediaStatus!) {
        if let mediaInfo = mediaStatus.mediaInformation {
            self.mediaDuration = mediaInfo.streamDuration
        }
        
        updateUIForMediaStatus(mediaStatus);
    }
}

extension ControlWindowController: NSWindowDelegate {
    override func windowDidLoad() {
        if (device != nil) {
            prepareUI(forDevice: self.device!)
        }
    }
}