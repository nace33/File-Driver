//
//  FormLabelCustomPicker.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI
import BOF_SecretSauce

struct FormCustomPicker<T:Hashable> : View {
    let title        : String
    let selection    : Binding<String>
    let options      : [T]
    let customOption : T
    let titleKey     : KeyPath<T,String>
    let optionFor    :(String) -> T
    
    init(_ title: String, selection: Binding<String>, options: [T], customOption: T, titleKey: KeyPath<T, String>, optionFor: @escaping (String) -> T) {
        self.title = title
        self.selection = selection
        self.options = options
        self.customOption = customOption
        self.titleKey = titleKey
        self.optionFor = optionFor
        self.isFocused = isFocused
    }
    
    @FocusState private var isFocused
    
    var body: some View {
        LabeledContent{
            VStack(alignment:.trailing, spacing:11) {
                Picker(title, selection: selectionBinding) {
                    ForEach(options, id:\.self) { t in
                        if t == customOption { Divider() }
                        Text(t[keyPath:titleKey])
                    }
                } currentValueLabel: {
                    Text(selectionBinding.wrappedValue[keyPath: titleKey])
                }
                
                if optionFor(selection.wrappedValue) == customOption {
                    TextField("", text:selection, prompt: Text("Enter \(title.lowercased()) here."))
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                }
            }
        } label: {
            EmptyView()
        }
            .labeledContentStyle(.fixedWidth)
            .onChange(of: selection.wrappedValue) { oldValue, newValue in
                processSelectionValue()
            }
            .onAppear() {
                processSelectionValue()
            }
    }
    func processSelectionValue() {
        if optionFor(selection.wrappedValue) == customOption && selection.wrappedValue == customOption[keyPath: titleKey] {
            selection.wrappedValue = ""
            isFocused = true
        }
    }
    var selectionBinding : Binding<T> {
        Binding {
            optionFor(selection.wrappedValue)
        } set: { newValue in
            selection.wrappedValue = newValue[keyPath: titleKey]
        }
    }
}



struct FormCustomEnumPicker<T:Hashable> : View  where T : RawRepresentable, T.RawValue == String {
    let title        : String
    let selection    : Binding<String>
    let titleKey     : KeyPath<T,String>
    let options      : [T]
    let customOption : T
    init(_ title: String, selection: Binding<String>, options: [T], customOption: T, titleKey: KeyPath<T,String> = \.rawValue.camelCaseToWords) {
        self.title = title
        self.selection = selection
        self.options = options
        self.customOption = customOption
        self.titleKey = titleKey
    }
    @FocusState private var isFocused
    
    func validString(_ string:String) -> T.RawValue {
        for option in options {
            if string.lowercased() == option.rawValue.lowercased() {
                return option.rawValue
            } else if string.wordsToCamelCase() == option.rawValue {
                return option.rawValue
            }
        }
        return customOption.rawValue
    }
    
    var body: some View {
        FormCustomPicker(title,
                         selection:selection,
                         options: options,
                         customOption: customOption,
                         titleKey:titleKey) {  T(rawValue:validString($0)) ?? customOption   }
    }
}


fileprivate enum TesterEnum : String, CaseIterable {
    case optionA, optionB, custom
}
#Preview {
    @Previewable @State var testString = TesterEnum.custom.rawValue
    @Previewable @State var test : TesterEnum = .custom
    Form {
        Section {
            FormCustomPicker("Test Options", selection: $testString, options: TesterEnum.allCases, customOption: .custom, titleKey: \.rawValue) { str in
                TesterEnum(rawValue: str) ?? .custom
            }
 
            FormCustomEnumPicker("Text Options2", selection: $testString, options: TesterEnum.allCases, customOption: .custom, titleKey: \.rawValue.camelCaseToWords)
        }
        
        LabeledContent("Selected Value") { Text(testString)}

    }.formStyle(.grouped)
}
