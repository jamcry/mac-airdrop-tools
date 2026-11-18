#!/usr/bin/env swift
import Cocoa
import Foundation

class AirDropStatusBarApp: NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    var statusItem: NSStatusItem?
    var sharingService: NSSharingService?
    var droppedFileURL: URL?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== AirDrop Share App Starting ===")
        print("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        
        // Create status bar item with a menu for better visibility
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("ERROR: Failed to create status item")
            NSApplication.shared.terminate(nil)
            return
        }
        
        print("Status item created successfully")
        
        // Create menu for better discoverability
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "AirDrop Share - Running!", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Drag files here to share via AirDrop", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        print("Menu created and attached")
        
        guard let button = statusItem.button else {
            print("ERROR: Failed to get status bar button")
            NSApplication.shared.terminate(nil)
            return
        }
        
        // Try multiple approaches to make it visible
        // First, try with a longer, more visible text
        button.title = "✈ AirDrop"
        button.toolTip = "Drag files here to share via AirDrop"
        button.appearsDisabled = false
        button.isEnabled = true
        
        // Force button to be visible
        button.isHidden = false
        
        print("Button configured - title: '\(button.title)', frame: \(button.frame)")
        print("Button isHidden: \(button.isHidden), isEnabled: \(button.isEnabled)")
        
        // Create a custom view that handles drag and drop
        // Make it cover the entire button area
        let dragView = DraggableButtonView(frame: NSRect(x: 0, y: 0, width: button.bounds.width, height: button.bounds.height))
        dragView.appDelegate = self
        dragView.button = button
        dragView.statusItem = statusItem
        dragView.autoresizingMask = [.width, .height]
        
        // Disable button interaction during drag (but allow clicks for menu)
        // Add drag view as a subview
        button.addSubview(dragView, positioned: .above, relativeTo: nil)
        
        // Register for multiple drag types to ensure we catch file drops
        let dragTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("public.file-url")
        ]
        dragView.registerForDraggedTypes(dragTypes)
        
        print("Drag view created and registered for drag types: \(dragTypes)")
        print("Drag view frame: \(dragView.frame), button frame: \(button.frame)")
        
        print("✅ Status bar item fully configured: '\(button.title)'")
        print("Look for '✈ AirDrop' in your menu bar (usually on the right side)")
        print("You can also click anywhere in the menu bar area to see if the menu appears")
        
        // Handle command line arguments (for backward compatibility)
        let args = CommandLine.arguments
        if args.count > 1 {
            let filePath = args[1]
            if FileManager.default.fileExists(atPath: filePath) {
                shareFile(URL(fileURLWithPath: filePath))
            } else {
                // Try to find newest file in directory
                findAndShareNewestFile(in: filePath)
            }
        }
    }
    
    func findAndShareNewestFile(in searchPath: String) {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: searchPath, isDirectory: true)
        
        guard fileManager.fileExists(atPath: searchPath) else {
            print("Path not found: \(searchPath)")
            NSApplication.shared.terminate(nil)
            return
        }
        
        // Find all .ipa files (or .md for testing)
        var files: [(url: URL, date: Date)] = []
        
        if let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "ipa" || fileURL.pathExtension == "md" {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey]),
                       let creationDate = resourceValues.creationDate {
                        files.append((url: fileURL, date: creationDate))
                    }
                }
            }
        }
        
        guard !files.isEmpty else {
            print("No files found in: \(searchPath)")
            NSApplication.shared.terminate(nil)
            return
        }
        
        let latestFile = files.sorted { $0.date > $1.date }.first!.url
        shareFile(latestFile)
    }
    
    func shareFile(_ fileURL: URL) {
        guard let airdrop = NSSharingService(named: .sendViaAirDrop) else {
            print("AirDrop service not available")
            NSApplication.shared.terminate(nil)
            return
        }
        
        guard airdrop.canPerform(withItems: [fileURL]) else {
            print("AirDrop cannot perform with this file")
            NSApplication.shared.terminate(nil)
            return
        }
        
        print("Sharing file: \(fileURL.path)")
        droppedFileURL = fileURL
        sharingService = airdrop
        airdrop.delegate = self
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            airdrop.perform(withItems: [fileURL])
        }
    }
    
    // MARK: - NSSharingServiceDelegate
    
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        print("AirDrop transfer completed successfully")
        NSApplication.shared.terminate(nil)
    }
    
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        print("AirDrop transfer failed: \(error.localizedDescription)")
        NSApplication.shared.terminate(nil)
    }
}

class DraggableButtonView: NSView {
    weak var button: NSButton?
    weak var appDelegate: AirDropStatusBarApp?
    weak var statusItem: NSStatusItem?
    var isDragging = false
    var savedMenu: NSMenu?
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let superview = superview {
            self.frame = superview.bounds
            // Make sure we can receive drag events
            self.wantsLayer = true
            print("Drag view moved to superview, frame: \(self.frame)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    func restoreMenu() {
        if let statusItem = statusItem {
            if let savedMenu = savedMenu {
                statusItem.menu = savedMenu
            } else {
                // Recreate menu if not saved
                let menu = NSMenu()
                menu.addItem(NSMenuItem(title: "AirDrop Share", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Drag files here to share via AirDrop", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                statusItem.menu = menu
            }
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("🖱️  Drag entered!")
        isDragging = true
        if let button = button, let statusItem = statusItem {
            // Save current menu
            savedMenu = statusItem.menu
            // Remove menu during drag to prevent interference
            statusItem.menu = nil
            button.title = "Release to send"
            button.contentTintColor = .systemBlue
            print("Button updated to 'Release to send'")
        }
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("🖱️  Drag exited")
        isDragging = false
        if let button = button {
            button.title = "✈ AirDrop"
            button.contentTintColor = nil
            restoreMenu()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("🖱️  Perform drag operation called!")
        isDragging = false
        if let button = button {
            button.title = "✈ AirDrop"
            button.contentTintColor = nil
            restoreMenu()
        }
        
        let pasteboard = sender.draggingPasteboard
        print("Pasteboard types: \(pasteboard.types)")
        
        // Try multiple methods to get the file URL
        var fileURL: URL?
        
        // Method 1: Try reading as NSURL objects
        if let files = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstFile = files.first {
            fileURL = firstFile
            print("✅ Got file via NSURL: \(firstFile.path)")
        }
        // Method 2: Try reading file URLs directly
        else if let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]) as? [URL],
                let firstFile = files.first {
            fileURL = firstFile
            print("✅ Got file via file URLs: \(firstFile.path)")
        }
        // Method 3: Try reading property list (legacy method)
        else if let files = pasteboard.propertyList(forType: .fileURL) as? [String],
                let firstPath = files.first,
                let url = URL(string: firstPath) {
            fileURL = url
            print("✅ Got file via property list: \(url.path)")
        }
        // Method 4: Try NSFilenamesPboardType (legacy)
        else if let files = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String],
                let firstPath = files.first {
            fileURL = URL(fileURLWithPath: firstPath)
            print("✅ Got file via NSFilenamesPboardType: \(firstPath)")
        }
        
        guard let url = fileURL else {
            print("❌ Failed to get file URL from pasteboard")
            return false
        }
        
        print("📤 Sharing file: \(url.path)")
        appDelegate?.shareFile(url)
        return true
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        // Allow clicks to pass through to button for menu
        super.mouseDown(with: event)
    }
}

// Main entry point
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AirDropStatusBarApp()
app.delegate = delegate

app.run()
