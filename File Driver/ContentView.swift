//
//  ContentView 2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/4/25.
//


//
//  ContentView.swift
//  Sidebar_SwiftData
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter:#Predicate<Sidebar_Item>{ $0.parent == nil }, sort:\Sidebar_Item.order) private var roots: [Sidebar_Item]
    
    @State private var showAddSheet = false
    @Environment(\.undoManager) private var undoManager
    @Environment(Google.self)  var google
    @SceneStorage(BOF_Nav.storageKey) var navigation = BOF_Nav()
    
    
    var initialSidebarItemID : Sidebar_Item.ID?
    init(sidebarItemID:Sidebar_Item.ID? = nil) {  initialSidebarItemID = sidebarItemID   }
    var title : String { Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "My App Name"  }
    var body: some View {
        if roots.isEmpty || google.user == nil {
            if google.loginStatus == .signingIn { ProgressView("Logging into Google...")}
            else { getStartedView }
        } else {
            NavigationSplitView {
                VStack(alignment:.leading) {
                    Sidebar()
                    Google_SignInView().padding()
                }
                .navigationTitle(title)
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            } detail: {
                contentView(navigation.sidebarID)
            }
/*
            NavigationSplitView {
                VStack(alignment:.leading) {
                    Sidebar()
                    Google_SignInView().padding()
                }
                .navigationTitle(title)
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            }
            content: {
                contentView(navigation.sidebarID)
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 250, ideal: 250)
#endif
            }
            detail: {
                detailView(navigation.sidebarID)
            }
 */
                .onAppear() {
                    BOF_SwiftData.shared.container.mainContext.undoManager = undoManager
                    loadNavigationPassedFromWindowGroupIfAny()
                    Task {
                      await   Google_Labels.shared.printFields(labelID: "5dXa8qxUu5p2F2tXDmsjdRxIU9cj81MWozIRNNEbbFcb")
                    }
                }
                .environment(navigation)
                .navigationSplitViewStyle(.prominentDetail)
        }
    }
    
    //MARK: Welcome - Get Started
    @ViewBuilder var getStartedView : some View {
        Spacer()
        Text("Welcome to File Driver 2.0")
            .font(.largeTitle)
        Image(nsImage: NSImage(named: "BOF_Logo")!)
        if roots.isEmpty  {
            Button("Load Sidebar") {getStarted() }
        } else {
            Google_SignInView().padding(40)
        }
        Spacer()
    }
    func getStarted() {
        BOF_SwiftData.shared.loadDefaultSidebar()
        try? BOF_SwiftData.shared.container.mainContext.save()
    }
    
    //For when sidebaritems are passed in from the Window Group
    private func loadNavigationPassedFromWindowGroupIfAny() {
        if let initialSidebarItemID {
            navigation.sidebarID = initialSidebarItemID
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Sidebar_Item.self, inMemory: true)
}


extension ContentView {
    @ViewBuilder func contentView(_ id:Sidebar_Item.ID?) -> some View {
        if let item = Sidebar_Item.fetchItem(with:id, in:modelContext) {
            switch item.category {
            case .filing:
                Filing_Content()
                    .navigationTitle(item.category.title)
            case .templates:
                Templates_Content()
                    .navigationTitle(item.category.title)
            case .inbox:
                Inbox_View(url: item.category.defaultURL)
                    .navigationTitle(item.category.title)
            case .settings:
                Settings_View()
                    .navigationTitle(item.category.title)
            case .cases:
                Cases_Content()
                    .navigationTitle(item.category.title)
            case .contacts:
                Contacts_Content()
                    .navigationTitle(item.category.title)
            case .drive:
                Filing_WebView(URL(string:"https://drive.google.com")!)
                    .navigationTitle(item.category.title)
            case .calendar:
                Filing_WebView(URL(string:"https://calendar.google.com")!)
                    .navigationTitle(item.category.title)
            case .gemini:
                Filing_WebView(URL(string:"https://gemini.google.com")!)
                    .navigationTitle(item.category.title)
            case .research:
                Research_Content()
                    .navigationTitle(item.category.title)
            default:
                Text("Jimmy Build \(item.category.title)\n\n\(item.url)")
            }
        } else {
            ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select an item from the sidebar"))
                          .navigationTitle(title)
        }
    }
    @ViewBuilder func detailView(_ id:Sidebar_Item.ID?) -> some View {
        if let item = Sidebar_Item.fetchItem(with:id, in:modelContext) {
            switch item.category {
            case .filing:
                Filing_Detail()
            case .contacts:
                Contacts_Detail()
            case .cases:
                Cases_Detail()
            case .templates:
                Templates_Detail()
            default:
                Spacer()
                           .navigationSplitViewColumnWidth(0)
            }
        }
    }
}

