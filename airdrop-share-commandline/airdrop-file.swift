#!/usr/bin/env swift
import Cocoa
import Foundation

class AirDropCLI: NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    var sharingService: NSSharingService?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        
        if args.contains("--help") || args.contains("-h") || args.count < 2 {
            printUsage()
            exit(0)
        }
        
        var targetPath: String?
        var findNewest = false
        var targetExtension: String?
        
        var i = 1
        while i < args.count {
            let arg = args[i]
            if arg == "--newest" {
                findNewest = true
            } else if arg.hasPrefix("--extension=") {
                targetExtension = arg.replacingOccurrences(of: "--extension=", with: "")
            } else if !arg.hasPrefix("-") {
                targetPath = arg
            }
            i += 1
        }
        
        guard let path = targetPath else {
            print("Error: No path provided.")
            printUsage()
            exit(1)
        }
        
        let expandedPath = NSString(string: path).expandingTildeInPath
        let fileURL: URL
        
        if findNewest {
            guard let newestFile = findNewestFile(in: expandedPath, extension: targetExtension) else {
                print("Error: No matching files found in \(expandedPath)")
                exit(1)
            }
            fileURL = newestFile
        } else {
            fileURL = URL(fileURLWithPath: expandedPath)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                print("Error: File not found at \(fileURL.path)")
                exit(1)
            }
        }
        
        shareFile(fileURL)
    }
    
    func printUsage() {
        print("""
        Usage: airdrop-file <file_path>
               airdrop-file --newest [--extension=<ext>] <directory_path>

        Options:
          --newest             Find the newest file in the specified directory.
          --extension=<ext>    Filter by file extension when using --newest.
          -h, --help           Show this help message.
        """)
    }
    
    func findNewestFile(in directoryPath: String, extension targetExt: String?) -> URL? {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
        
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryPath, isDirectory: &isDir), isDir.boolValue else {
            print("Error: \(directoryPath) is not a directory or does not exist.")
            return nil
        }
        
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isDirectoryKey]
        guard let enumerator = fileManager.enumerator(at: directoryURL, 
                                                     includingPropertiesForKeys: keys, 
                                                     options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) else {
            return nil
        }
        
        var files: [(url: URL, date: Date)] = []
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let isDirectory = resourceValues.isDirectory, !isDirectory,
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }
            
            if let targetExt = targetExt {
                if fileURL.pathExtension.lowercased() == targetExt.lowercased() {
                    files.append((url: fileURL, date: modificationDate))
                }
            } else {
                files.append((url: fileURL, date: modificationDate))
            }
        }
        
        return files.sorted { $0.date > $1.date }.first?.url
    }
    
    func shareFile(_ fileURL: URL) {
        guard let airdrop = NSSharingService(named: .sendViaAirDrop) else {
            print("Error: AirDrop service not available.")
            exit(1)
        }
        
        guard airdrop.canPerform(withItems: [fileURL]) else {
            print("Error: AirDrop cannot share this file: \(fileURL.path)")
            exit(1)
        }
        
        print("Sharing: \(fileURL.path)...")
        self.sharingService = airdrop
        airdrop.delegate = self
        
        // AirDrop UI requires the app to be active
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            airdrop.perform(withItems: [fileURL])
        }
    }
    
    // MARK: - NSSharingServiceDelegate
    
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        print("Success: File shared via AirDrop.")
        exit(0)
    }
    
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        print("Error: AirDrop failed - \(error.localizedDescription)")
        exit(1)
    }
}

// Set up the application
let app = NSApplication.shared
let delegate = AirDropCLI()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

























