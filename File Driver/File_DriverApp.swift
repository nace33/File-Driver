//
//  File_DriverApp.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI
import SwiftData

@main
struct File_DriverApp: App {
    @State private var google = Google.shared
    @State private var contacts = ContactsController.shared
    @State private var templates = TemplatesController.shared
    @State private var filing = FilingController.shared
    
    @State private var swiftData  = BOF_SwiftData.shared
    var body: some Scene {
        WindowGroup(id:"default", for: Sidebar_Item.ID.self) { id in
            ContentView(sidebarItemID: id.wrappedValue)
//            GoogleDrive_IconDownload(size:.sixtyFour)
        }
            .environment(google)
            .environment(filing)
            .environment(contacts)
            .environment(templates)
            .modelContainer(swiftData.container)
#if os(macOS)
            .commands {
                ImportFromDevicesCommands()
            }
#endif
        
#if os(macOS)
        Settings {
            Settings_View()
                .environment(google)
                .modelContainer(swiftData.container)
        }
#endif

    }
}
//TABS

/*
 @Environment(\.openWindow) var openWindow
 Button("Open In New Window") {  openWindow(id: "default", value: item)  }
 WindowGroup(id:"default", for: Sidebar_Item.self) { id in
*/
 
import BOF_SecretSauce
extension File_DriverApp {
 
    func createNewTab() { //default window
        if let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController {
          windowController.newWindowForTab(nil)
          if let newWindow = NSApp.keyWindow, currentWindow != newWindow {
              currentWindow.addTabbedWindow(newWindow, ordered: .above)
            }
        }
    }
    static func createNewTab(hostingView:(NSWindow) -> (NSView) ) {
        if let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController {
            windowController.newWindowForTab(nil)
            if let newWindow = NSApp.keyWindow, currentWindow != newWindow {
                //Options
                newWindow.toolbar = NSToolbar()
                newWindow.titleVisibility = .visible
                newWindow.contentView = hostingView(newWindow)
                currentWindow.addTabbedWindow(newWindow, ordered: .above)
            }
        }
    }

    static func createWebViewTab(url:URL, title:String) {
        File_DriverApp.createNewTab() { window in
            let navView = Filing_WebView(url)
                .navigationTitle(title)
//                .environment(Google.shared)
            return NSHostingView(rootView:navView)
        }
    }
//    static func createInboxTab() {
//        File_DriverApp.createNewTab() { window in
//            let navView =  Inbox_View().navigationTitle("Inbox")
//            return NSHostingView(rootView:navView)
//        }
//    }

}

