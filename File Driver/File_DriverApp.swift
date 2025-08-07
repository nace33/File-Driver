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

    @State private var swiftData  = BOF_SwiftData.shared
    @Environment(\.openURL) var openURL
    @Environment(\.openWindow) var openWindow

    
    var body: some Scene {
        WindowGroup(id:"default", for: Sidebar_Item.ID.self) { id in
            ContentView(sidebarItemID: id.wrappedValue)
                .onOpenURL { url in
                    FileDriver_URLScheme.handle(url)
                }
        }
        
            .environment(google)
            .environment(contacts)
            .environment(templates)
            .modelContainer(swiftData.container)
#if os(macOS)
            .commands {
                ImportFromDevicesCommands()
                CommandGroup(before: CommandGroupPlacement.newItem, addition: {
                    Button { createNewTab()  } label: { Text("New Tab") }
                        .keyboardShortcut("t", modifiers: [.command])
                    Button { createSampleURL()  } label: { Text("New Sample URL") }
                        .keyboardShortcut("e", modifiers: [.command])
                })
            }

#endif
        
        WindowGroup(id:"SwiftData", for:BOF_SwiftDataView.ModelType.self) { type in 
            BOF_SwiftDataView(modelType: type.wrappedValue ?? .filing)
                .navigationTitle("File Driver Swift Database")
        }
            .modelContainer(swiftData.container)
        
        WindowGroup(id:"WebView", for:URL.self) { url in
            Filing_WebView(url.wrappedValue ?? URL(string: "about:blank")!)
        }
            .modelContainer(swiftData.container)

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
#if os(macOS)
extension File_DriverApp {
    func createSampleURL() {
//        if let newURL = FileDriver_URLScheme.create(category: .cases, action: .openDocument, id: "Hello") {
//            openWindow.callAsFunction(id: "default", value:Sidebar_Item.Category.cases.rawValue)
//            openURL.callAsFunction(newURL) { accepted in
//                print("Accepted: \(accepted) \(newURL)")
//            }
//        }
    }
    func createNewTab() { //default window
        if let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController {
          windowController.newWindowForTab(nil)
          if let newWindow = NSApp.keyWindow, currentWindow != newWindow {
              let url = URL(string:"https://developer.apple.com/documentation/swiftui/commandgroup/")!
              newWindow.contentView = NSHostingView(rootView:Filing_WebView(url))
              currentWindow.addTabbedWindow(newWindow, ordered: .above)
          } else {
              print("Failed to create new tabbed window")
          }
        } else {
            print("No Current Window")
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
    static func createWebViewInMainWindow(_ url:URL) {
        if let currentWindow = NSApp.mainWindow, let windowController = currentWindow.windowController {
          windowController.newWindowForTab(nil)
          if let newWindow = NSApp.mainWindow, currentWindow != newWindow {
              newWindow.contentView = NSHostingView(rootView:Filing_WebView(url))
              currentWindow.addTabbedWindow(newWindow, ordered: .above)
          } else {
              print("Failed to create new tabbed window")
          }
        } else {
            print("No Main Window")
        }
    }
//    static func createInboxTab() {
//        File_DriverApp.createNewTab() { window in
//            let navView =  Inbox_View().navigationTitle("Inbox")
//            return NSHostingView(rootView:navView)
//        }
//    }

}
#endif

