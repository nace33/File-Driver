//
//  Google_Label.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/10/23.
//


import SwiftUI
import GoogleAPIClientForREST_DriveLabels


@Observable
final class Google_Labels  {
    static let shared: Google_Labels = Google_Labels()
    var isLoading = false
    let service = GTLRDriveLabelsService()
    //https://developers.google.com/drive/labels/reference/rest/v2beta/labels/list
    let scopes  =  ["https://www.googleapis.com/auth/drive.labels"]
}


//MARK: Get
extension Google_Labels {
    func getLabel(id:String) async throws -> GTLRDriveLabels_GoogleAppsDriveLabelsV2Label {
        let query = GTLRDriveLabelsQuery_LabelsGet.query(withName: "labels/\(id)")
        query.view = kGTLRDriveLabelsViewLabelViewFull

        let fetcher = Google_Fetcher<GTLRDriveLabels_GoogleAppsDriveLabelsV2Label>(service:service, scopes:scopes)
        
        do {
            isLoading = true
            guard let response = try await Google.execute(query, fetcher: fetcher) else {
                isLoading = false
                throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
            }
            isLoading = false
            return response
        } catch {
            isLoading = false
            throw error
        }
    }
    func getAllLabels(publishedOnly:Bool = true) async throws -> [GTLRDriveLabels_GoogleAppsDriveLabelsV2Label] {
        let query = GTLRDriveLabelsQuery_LabelsList.query()
        query.publishedOnly = publishedOnly
        query.view = kGTLRDriveLabelsViewLabelViewFull

        let fetcher = Google_Fetcher<GTLRDriveLabels_GoogleAppsDriveLabelsV2ListLabelsResponse>(service:service, scopes:scopes)
        
        do {
            isLoading = true
            guard let response = try await Google.execute(query, fetcher: fetcher),
                  let labels = response.labels else {
                isLoading = false
                throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
            }
            isLoading = false
            return labels
        } catch {
            isLoading = false
            throw error
        }
    }
}


//MARK: Print
extension Google_Labels {
    func printFields(labelID:String) async {
        do {
            let label = try await getLabel(id: labelID)
            print("Label: \(label.title)")
            for field in label.fields ?? [] {
                print("Field:\t\(field.properties?.displayName ?? "No Display Name")\tID: \(field.identifier ?? "No ID")\tType: \(field.category.rawValue)")
                if field.category == .list, let arr = field.selectionIDsAndValues {
                    for a in arr {
                        print("\t\t\(a.value) ID: \(a.id)")
                    }
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    func printAll() async {
        do {
            let labels = try await getAllLabels()
            for label in labels {
                print("Label: \(label.title) (\(label.id))")
                for field in label.fields ?? [] {
                    print("\tField: \(field.properties?.displayName ?? "No Display Name") ID: \(field.identifier ?? "No ID")")
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
