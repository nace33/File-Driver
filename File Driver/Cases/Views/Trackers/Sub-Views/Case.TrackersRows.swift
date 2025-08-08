//
//  Case.TrackersRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/6/25.
//

import SwiftUI

//MARK: - Case.Tracker Row
struct Case_TrackerRow: View {
    @Binding var tracker : Case.Tracker
    let elements : [TrackerRoot.TextElement]
    let isSelected:Bool
    @Environment(TrackerDelegate.self) var delegate
    init(tracker: Binding<Case.Tracker>, elements: [TrackerRoot.TextElement], isSelected:Bool) {
        self._tracker = tracker
        self.elements = elements
        self.isSelected = isSelected
    }
    init(tracker: Binding<Case.Tracker>, groupedBy: TrackerDelegate.GroupBy, isSelected:Bool) {
        self._tracker = tracker
        self.elements = TrackerRoot.TextElement.standard(groupedBy: groupedBy)
        self.isSelected = isSelected
    }
    var body: some View {
        tracker.texts(elements: elements, aCase: delegate.aCase, isSelected: isSelected)
            .reduce(Text(""), +)
            .lineLimit(delegate.oneLineLimit ? 1 : nil)
    }

}

//MARK: - Case.Tracker Extension
extension Case.Tracker {
    func texts(elements:[TrackerRoot.TextElement], aCase:Case, isSelected:Bool) -> [Text] {
        var texts = [Text]()
        for element in elements {
            switch element {
            case .status:
                texts.append(Text("\(Image(systemName:"circle.fill"))  ").font(.system(size: 11)).foregroundStyle(status.color))
            case .date:
                texts.append(Text("\(date.mmddyyyy) "))
            case .category:
                texts.append(Text("\(categoryTitle) ").bold())
            case .contact:
                let contacts = aCase.contacts(with: contactIDs)
                for contact in contacts {
                    texts.append(Text(contact.name).foregroundStyle(isSelected ? .primary : Color.blue))
                    if contact != contacts.last {
                        texts.append(Text(", ").foregroundStyle(.primary))
                    } else {
                        texts.append(Text(" "))
                    }
                }
            case .tag:
                let tags = aCase.tags(with: tagIDs)
                for tag in tags {
                    texts.append(Text(tag.name).foregroundStyle(isSelected ? .primary : Color.green))
                    if tag != tags.last {
                        texts.append(Text(", ").foregroundStyle(.primary))
                    }else {
                        texts.append(Text(" "))
                    }
                }
            case .text:
                texts.append(Text("\(text) ").foregroundStyle(.secondary))
//            case .createdBy:
//                texts.append(Text("\(createdBy) ").foregroundStyle(.secondary))
            }
        }
        return texts
    }
}



//MARK: - Root Row
struct Case_TrackersSummaryRow: View {
    @Binding var root     : TrackerRoot
    let elements : [TrackerRoot.TextElement]
    init(root: Binding<TrackerRoot>, elements: [TrackerRoot.TextElement]) {
        self._root = root
        self.elements = elements
    }
    init(root: Binding<TrackerRoot>, groupedBy: TrackerDelegate.GroupBy) {
        self._root = root
        self.elements = TrackerRoot.TextElement.standard(groupedBy: groupedBy)
    }
    @Environment(TrackerDelegate.self) var delegate

 
    var body: some View {
        if root.isEmpty {
            Text("Trackers are all hidden.").foregroundStyle(.secondary)
        } else {
            root.texts(elements: elements, isSelected: root.id == delegate.selectedRootID)
                .reduce(Text(""), +)
                .lineLimit(delegate.oneLineLimit ? 1 : nil)

        }
    }
}


//MARK: - Root Extension
extension TrackerRoot {
    enum TextElement : CaseIterable {
        case status, date, category, contact, tag, text//, createdBy
        static func standard(groupedBy:TrackerDelegate.GroupBy) -> [TextElement] {
            switch groupedBy {
            case .none:
                Self.allCases
            case .status:
                Self.allCases.filter { $0 != .status }
            case .category:
                Self.allCases.filter { $0 != .category }
            case .date:
                Self.allCases
            case .createdBy:
                Self.allCases
            }
        }
    }
    func string(element:TextElement) -> String?{
        switch element {
        case .status:
            status.title
        case .date:
            date.mmddyyyy
        case .category:
            categoryTitle
        case .contact:
            contacts.map(\.name).joined(separator: ", ")
        case .tag:
            tags.map(\.name).joined(separator: ", ")
        case .text:
            text.isEmpty ? nil : text
        }
    }
    func string(elements:[TextElement], maxLength:Int? = nil) -> String {
        let elements = elements.compactMap({ string(element: $0)?.trimmingCharacters(in: .whitespaces)})
                               .filter { !$0.isEmpty }
        let str = elements.joined(separator:" ")
        guard let maxLength, maxLength < str.count  else { return str }
        let shorterString = String(str.prefix(maxLength)) + "…"
        return shorterString
    }
    func texts(elements:[TextElement], isSelected:Bool) -> [Text] {
        var texts = [Text]()
        for element in elements {
            switch element {
            case .status:
                texts.append(Text("\(Image(systemName:"circle.fill"))  ").font(.system(size: 11)).foregroundStyle(status.color))
            case .date:
                texts.append(Text("\(date.mmddyyyy) "))
            case .category:
                texts.append(Text("\(categoryTitle) ").bold())
            case .contact:
                for contact in self.contacts {
                    texts.append(Text(contact.name).foregroundStyle(isSelected ? .primary : Color.blue))
                    if contact != self.contacts.last {
                        texts.append(Text(", ").foregroundStyle(.primary))
                    } else {
                        texts.append(Text(" "))
                    }
                }
            case .tag:
                for tag in self.tags {
                    texts.append(Text(tag.name).foregroundStyle(isSelected ? .primary : Color.green))
                    if tag != self.tags.last {
                        texts.append(Text(", ").foregroundStyle(.primary))
                    }else {
                        texts.append(Text(" "))
                    }
                }
            case .text:
                texts.append(Text("\(text) ").foregroundStyle(.secondary))
//            case .createdBy:
//                texts.append(Text("\(createdBy) ").foregroundStyle(.secondary))
            }
        }
        return texts
    }
}
