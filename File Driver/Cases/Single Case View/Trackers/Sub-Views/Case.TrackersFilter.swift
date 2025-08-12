//
//  Case.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//
import SwiftUI

struct Case_TrackersFilter : View {
    @AppStorage("FileDriver.CaseTrackerView.showTable") private var showTable = false
    @AppStorage("FileDriver.Case_TrackersList.sortTableBy") private var sortBy : TrackerDelegate.SortBy = .date
    @AppStorage("FileDriver.Case_TrackersList.groupBy") private var groupBy = TrackerDelegate.GroupBy.none
    @Environment(TrackerDelegate.self) var delegate

    var body: some View {
     
        Picker("Show As", selection: $showTable) {Text("List").tag(false);Text("Table").tag(true); }
            .fixedSize()
        Picker("Group By", selection: $groupBy) {   ForEach(TrackerDelegate.GroupBy.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords)}  }
            .fixedSize()
        if !showTable {
            Picker("Sort By", selection: $sortBy) { ForEach(TrackerDelegate.SortBy.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords)}}
                .fixedSize()
        }
       
        Toggle("Hide Stopped Trackers", isOn:Bindable(delegate).hideStoppedTrackers)
        Toggle("Limit Row To 1 Line", isOn:Bindable(delegate).oneLineLimit)
    }
}
