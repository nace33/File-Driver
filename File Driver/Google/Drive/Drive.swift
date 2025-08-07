//
//  Drive.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 3/22/25.
//

import GoogleAPIClientForREST_Drive

@Observable
final class Drive {
    static let shared: Drive = { Drive() }() //Singleton
    let service =  GTLRDriveService()
    let scopes  =  [kGTLRAuthScopeDrive]
}

extension GTLRDrive_Drive {
    var asFolder : GTLRDrive_File {
        let folder = GTLRDrive_File()
        folder.identifier = identifier
        folder.name = name
        folder.mimeType = GTLRDrive_File.MimeType.folder.rawValue
        folder.driveId = identifier
        return folder
    }
}
extension GTLRDrive_File {
    var asFolder : GTLRDrive_File {
        let folder = GTLRDrive_File()
        folder.identifier = identifier
        folder.name = name
        folder.mimeType = GTLRDrive_File.MimeType.folder.rawValue
        folder.driveId = driveId
        return folder
    }
}

//MARK: Shared Drives
extension Drive {
    func sharedDriveList() async throws -> GTLRDrive_DriveList {
        let fetcher = Google_Fetcher<GTLRDrive_DriveList>(service:service, scopes:scopes)
        let query = GTLRDriveQuery_DrivesList.query()
        query.pageSize = 100
        do {
           
            return try await Google.execute(query, fetcher: fetcher)
        }catch {
            throw error
        }
    }
    func sharedDrivesAsFolders() async throws -> [GTLRDrive_File] {
        do {
            let driveList = try await sharedDriveList()
            let drives = driveList.drives ?? []
            let folders : [GTLRDrive_File] = drives.compactMap { $0.asFolder  }
            return folders
        }catch {
            throw error
        }
    }
    func sharedDrive(get id:String) async throws -> GTLRDrive_Drive {
        do {
            let fetcher = Google_Fetcher<GTLRDrive_Drive>(service:service, scopes:scopes)
            let query = GTLRDriveQuery_DrivesGet.query(withDriveId: id)
         
            
            return try await Google.execute(query, fetcher: fetcher)
        }catch {
            throw error
        }
        
    }
    func sharedDrive(new name:String) async throws -> GTLRDrive_Drive {
        do {
            let fetcher = Google_Fetcher<GTLRDrive_Drive>(service:service, scopes:scopes)
            let drive   = GTLRDrive_Drive()
            drive.name = name
            let query   = GTLRDriveQuery_DrivesCreate.query(withObject: drive, requestId: UUID().uuidString)
            do {
               
                return try await Google.execute(query, fetcher: fetcher)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    func sharedDrive(driveID:String, rename:String) async throws -> GTLRDrive_Drive {
        let fetcher = Google_Fetcher<GTLRDrive_Drive>(service:service, scopes:scopes)
        let drive   = GTLRDrive_Drive()
        drive.name = rename
        let query = GTLRDriveQuery_DrivesUpdate.query(withObject: drive, driveId: driveID)
        do {
       
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func sharedDrive(driveID:String, hide:Bool) async throws -> GTLRDrive_Drive {
        let fetcher = Google_Fetcher<GTLRDrive_Drive>(service:service, scopes:scopes)
        let query = hide ? GTLRDriveQuery_DrivesHide.query(withDriveId: driveID) : GTLRDriveQuery_DrivesUnhide.query(withDriveId: driveID)
        do {
           
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func sharedDrive(delete driveID:String) async throws -> Bool {
        let fetcher = Google_Fetcher<GTLRDrive_Drive?>(service:service, scopes:scopes)
        let query   = GTLRDriveQuery_DrivesDelete.query(withDriveId: driveID)
        do {
           
           // Upon successful completion, the callback's object and error parameters will be nil. This query does not fetch an object.
            //see GTLRDriveQuery_DrivesDelete
            return try await Google.execute(query, fetcher: fetcher)  == nil
        } catch {
            throw error
        }
    }
}

//MARK: - Permissions
extension Drive {
    func permission(add permission:GTLRDrive_Permission, fileID:String, sendEmail:Bool = false, emailMessage:String? = nil) async throws -> GTLRDrive_Permission {
        let query = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: fileID)
        query.fields = "displayName, emailAddress, role, type, domain, id, photoLink"
    
        if permission.type != "domain" { // The type of the grantee. Valid values are: * `user` * `group` * `domain` *  `anyone`
            query.sendNotificationEmail = sendEmail
            query.emailMessage = emailMessage
        }
        query.supportsAllDrives = true
        
        
        let fetcher = Google_Fetcher<GTLRDrive_Permission>(service:service, scopes:scopes)
        do {
            
         
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func permission(update permission:GTLRDrive_Permission, fileID:String) async throws -> GTLRDrive_Permission {
        guard let permissionID = permission.identifier else {
            throw Google_Error.didNotProvidePropertiesToMethod(#function)
        }

        let query = GTLRDriveQuery_PermissionsUpdate.query(withObject: permission, fileId: fileID, permissionId:permissionID)
        query.fields = "displayName, emailAddress, role, type, domain, id, photoLink"
        query.supportsAllDrives = true
        
        let fetcher = Google_Fetcher<GTLRDrive_Permission>(service:service, scopes:scopes)
        do {
          
            
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func permission(remove permission:GTLRDrive_Permission, fileID:String) async throws {
        guard let permissionID = permission.identifier else {
            throw Google_Error.didNotProvidePropertiesToMethod(#function)
        }
        let query = GTLRDriveQuery_PermissionsDelete.query(withFileId: fileID, permissionId: permissionID)
        query.supportsAllDrives = true
        let fetcher = Google_Fetcher<Void>(service:service, scopes:scopes)
        do {
            try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func permission(matching email:String, fileID:String) async throws -> GTLRDrive_Permission {
        do {
            guard let permission = try await permissions(fileID: fileID).first(where: { $0.emailAddress == email }) else {
                throw Google_Error.noAccessToThisItem
            }
            return permission

        } catch {
            throw error
        }
    }
    func permissions(fileID:String) async throws -> [GTLRDrive_Permission] {
        let query = GTLRDriveQuery_PermissionsList.query(withFileId:fileID)
        query.supportsAllDrives = true
        query.fields = "permissions(displayName, emailAddress, role, type, domain, id, photoLink)"
        let fetcher = Google_Fetcher<GTLRDrive_PermissionList>(service:service, scopes:scopes)
        do {
            let permissionList = try await Google.execute(query, fetcher: fetcher)
            guard let permissions = permissionList.permissions else {
                throw Google_Error.driveCallSuceededButDidNotReturnAsExpected("No Permissions")
            }
            return permissions
        } catch {
            throw error
        }
    }
}


//MARK: Folders
extension Drive {
    func getContents(driveID:String, labelIDs:[String]? = nil, onlyFolders:Bool = false, orderBy:String = "name", fetcher:Google_Fetcher<GTLRDrive_FileList>? = nil) async throws ->  [GTLRDrive_File] {
        let f = fetcher ?? Google_Fetcher(service:service, scopes:scopes)
        let query = GTLRDriveQuery_FilesList.query()
        query.supportsAllDrives = true
        query.includeItemsFromAllDrives = true
        query.orderBy = orderBy
        query.driveId = driveID
        query.corpora = "drive"
        if !onlyFolders, let labelIDs {
            query.includeLabels = labelIDs.commify
        }
        query.fields = GTLRDrive_File.queryFolderFields
        query.q = onlyFolders ?  "mimeType='application/vnd.google-apps.folder' and trashed=false" : "trashed=false"
        do {
            let list: GTLRDrive_FileList = try await Google.execute(query, fetcher: f)
            if let files = list.files {
                
                return onlyFolders ? files.filter { $0.isFolder} : files
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
    }
    func getContents(of folderID:String?, fields:[GTLRDrive_File.QueryField]? = nil, labelIDs:[String]? = nil, onlyFolders:Bool = false, orderBy:String = "name", fetcher:Google_Fetcher<GTLRDrive_FileList>? = nil) async throws ->  [GTLRDrive_File] {
        guard let folderID else {
            return try await Drive.shared.sharedDrivesAsFolders()
        }
        let f = fetcher ?? Google_Fetcher(service:service, scopes:scopes)
        
        let query = GTLRDriveQuery_FilesList.query()
        query.supportsAllDrives = true
        query.includeItemsFromAllDrives = true
        query.orderBy = orderBy
        if !onlyFolders, let labelIDs {
            query.includeLabels = labelIDs.commify
        }
        query.fields = GTLRDrive_File.QueryField.fieldsString(fields ?? GTLRDrive_File.QueryField.allCases, isFolder: true)
        
        if onlyFolders {
            query.q = "mimeType='application/vnd.google-apps.folder' and '\(folderID)' in parents and trashed=false"
        } else {
            query.q = "'\(folderID)' in parents and trashed=false"
        }
        do {
            let list: GTLRDrive_FileList = try await Google.execute(query, fetcher: f)
            if let files = list.files {
                return  files
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
    }
    func get(folder name:String, parentID:String, createIfNotFound:Bool = false, caseInsensitive:Bool = true) async throws -> GTLRDrive_File {
        guard name.isEmpty == false, parentID.isEmpty == false else { throw Google_Error.didNotProvidePropertiesToMethod(#function) }
        do {
            let folders = try await getContents(of: parentID, onlyFolders: true)
            if let folder = folders.first(where: {caseInsensitive ? $0.title.lowercased() == name.lowercased() : $0.title == name}) {
                return folder
            }
            else if createIfNotFound {
                return try await create(folder:name, in: parentID)
            } else {
                throw Google_Error.itemNotFound
            }
        } catch {
            throw error
        }
    }
    func create(folder name:String, in parentID:String, mustBeUnique:Bool = false, description:String? = nil) async throws -> GTLRDrive_File {
        guard name.isEmpty == false, parentID.isEmpty == false else { throw Google_Error.didNotProvidePropertiesToMethod(#function) }
        var folderName = name
        if mustBeUnique {
            do {
                let contents = try await Drive.shared.getContents(of: parentID, onlyFolders: true)
                let names = contents.compactMap { $0.title }
                var testName = folderName
                var iterator = 2
                while names.contains(testName) {
                    testName = "\(folderName) \(iterator)"
                    iterator += 1
                }
                folderName = testName
            } catch {
                throw error
            }
            
        }
        let folder = GTLRDrive_File()
        folder.name = folderName
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.descriptionProperty = description
        if parentID.count > 0 {
            folder.parents = [parentID]
        }
    
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        query.supportsAllDrives = true
        query.fields = GTLRDrive_File.queryFileFields

        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
        do {
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}

//MARK: Files
extension Drive {
    func get(fileID:String, labelIDs:[String]? = nil) async throws -> GTLRDrive_File {
        let query = GTLRDriveQuery_FilesGet.query(withFileId: fileID)
        query.supportsAllDrives = true
        query.fields = GTLRDrive_File.queryFileFields
        if let labelIDs {
            query.includeLabels = labelIDs.commify
        }

        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
        
        do {
      
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func getParents(for id:String) async throws -> [GTLRDrive_File] {
        var stack : [GTLRDrive_File] = []
        do {
            let file = try await get(fileID: id)
            guard let driveID = file.driveId else {
                throw Google_Error.driveCallSuceededButDidNotReturnAsExpected("No Drive ID Found for \(id)")
            }
            let drive = try await Drive.shared.sharedDrive(get: driveID).asFolder

            if file.id == drive.id { return [drive] }
            else if file.isFolder { stack.append(file)}
            var parentID = file.parents?.first
            while parentID != nil {
                let parentFile = try await Drive.shared.get(fileID: parentID!)
                if parentFile.id == driveID {
                    stack.insert(drive, at: 0)//use the drive file because the name does not come across on the file fetch
                    break
                } else {
                    stack.insert(parentFile, at: 0)
                    parentID = parentFile.parents?.first
                }
            }
            return stack
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    func get(filesWithLabelID:String, labelQuery:String? = nil, orderBy:String = "name", driveID:String? = nil) async throws -> [GTLRDrive_File] {
        let query = GTLRDriveQuery_FilesList.query()
        query.supportsAllDrives = true
        query.includeItemsFromAllDrives = true
        query.includeLabels = filesWithLabelID
        query.fields = GTLRDrive_File.queryFolderFields
        query.q = labelQuery ?? "'labels/\(filesWithLabelID)' in labels and trashed=false"
        query.orderBy = orderBy
        
        if let driveID {
            query.corpora = "drive"
            query.driveId = driveID
        } else {
            query.corpora = "allDrives"
        }
        
        let fetcher = Google_Fetcher<GTLRDrive_FileList>(service:service, scopes:scopes)
        
        do {
            let result = try await Google.execute(query, fetcher: fetcher)
            guard let files = result.files else {
                throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
            }
            return files
        } catch {
            print("Error \(#function): \(error.localizedDescription)")
            throw error
        }
    }
    func create(fileType:GTLRDrive_File.MimeType, name:String, parentID:String, description:String? = nil) async throws -> GTLRDrive_File {
        do {
            let file = GTLRDrive_File()
            file.mimeType = fileType.rawValue
            file.name = name
            file.parents = [parentID]
            file.descriptionProperty = description

            let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
            query.supportsAllDrives = true
            query.fields = GTLRDrive_File.queryFileFields
            let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
            
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            print("Error \(#function): \(error.localizedDescription)")
            throw error
        }
    }
}

//MARK: -Copy
extension Drive {
    func copy(fileID:String, rename newName:String, saveTo destinationID:String) async throws -> GTLRDrive_File {
        let newFile = GTLRDrive_File()
        newFile.name = newName
//        newFile.mimeType = mime
        newFile.parents = [destinationID]
        
        let query = GTLRDriveQuery_FilesCopy.query(withObject: newFile, fileId:fileID)
        query.fields = GTLRDrive_File.queryFileFields
        query.supportsAllDrives = true
        
        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
        do {
         
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func copy(files:[GTLRDrive_File], to destinationID:String) async throws -> GTLRBatchResult {
        let batch = GTLRBatchQuery()
        for file in files {
            let newFile = GTLRDrive_File()
            newFile.name = file.name
            newFile.parents = [destinationID]

            let query = GTLRDriveQuery_FilesCopy.query(withObject: newFile, fileId:file.id)
            
            query.fields = GTLRDrive_File.queryFileFields
            query.supportsAllDrives = true
            
            batch.addQuery(query)
        }
        let fetcher = Google_Fetcher<GTLRBatchResult>(service: service, scopes: scopes)
        do {
        
            return try await Google.executeBatch(batch, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}
//MARK: -Move
extension Drive {
    func move(file:GTLRDrive_File, to folder:GTLRDrive_File) async throws -> GTLRDrive_File {
        do {
            guard let fileID = file.identifier else { throw Google_Error.driveIDIsEmpty(file.title)}
            guard let parentID = file.parents?.first else { throw Google_Error.driveParentIDIsEmpty(file.title)}
            guard let destinationID = folder.identifier else { throw Google_Error.driveIDIsEmpty(folder.title)}
            guard parentID != destinationID else { return file /*Already in this folder */}
            return try await move(fileID: fileID, from: parentID, to: destinationID)
        } catch {
            throw error
        }
    }
    func move(fileID:String, from parentID:String,  to destinationID:String) async throws -> GTLRDrive_File {

        let query = GTLRDriveQuery_FilesUpdate.query(withObject: GTLRDrive_File(), fileId:fileID, uploadParameters: nil)
        query.removeParents = parentID
        query.addParents = destinationID
        
        query.fields = GTLRDrive_File.queryFileFields
        query.supportsAllDrives = true
        
        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
        do {
          
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func move(files:[GTLRDrive_File], to destinationID:String) async throws -> GTLRBatchResult {
        let batch = GTLRBatchQuery()
        for file in files {
            let newFile = GTLRDrive_File()
            newFile.name = file.name
            let query = GTLRDriveQuery_FilesUpdate.query(withObject:newFile, fileId:file.id, uploadParameters: nil)
            query.removeParents = file.parents?.first
            query.addParents = destinationID
            
            query.fields = GTLRDrive_File.queryFileFields
            query.supportsAllDrives = true
            
            batch.addQuery(query)
        }
        let fetcher = Google_Fetcher<GTLRBatchResult>(service: service, scopes: scopes)
        do {
        
            return try await Google.executeBatch(batch, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func move(tuples:[(fileID:String, parentID:String, destinationID:String)]) async throws -> GTLRBatchResult {
        let batch = GTLRBatchQuery()
        for tuple in tuples {
            let query = GTLRDriveQuery_FilesUpdate.query(withObject: GTLRDrive_File(), fileId:tuple.fileID, uploadParameters: nil)
            query.removeParents = tuple.parentID
            query.addParents = tuple.destinationID
            
            query.fields = GTLRDrive_File.queryFileFields
            query.supportsAllDrives = true
            
            batch.addQuery(query)
        }
        let fetcher = Google_Fetcher<GTLRBatchResult>(service: service, scopes: scopes)
        do {
        
            return try await Google.executeBatch(batch, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}

//MARK: -Update
///the GTLRDrive_File can NOT contain values that are not writable (such as an 'id')
///This is because the server will reject the update because it is trying to over-write an unwritable property
extension Drive {
    func update(id:String, with file:GTLRDrive_File) async throws -> GTLRDrive_File {
        let query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: id, uploadParameters: nil)
        query.supportsAllDrives = true
        query.fields = GTLRDrive_File.queryFileFields
        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes)
        do {
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func rename(id:String, newName:String) async throws -> GTLRDrive_File {
        let file = GTLRDrive_File()
        file.name = newName
        do {
            return try await update(id:id, with: file)
        } catch {
            throw error
        }
    }
    func update(tuples:[(id:String, file:GTLRDrive_File)]) async throws -> GTLRBatchResult {
        let batch = GTLRBatchQuery()
        for tuple in tuples {
            let query = GTLRDriveQuery_FilesUpdate.query(withObject: tuple.file, fileId: tuple.id, uploadParameters: nil)
            query.supportsAllDrives = true
            query.fields = GTLRDrive_File.queryFileFields
            batch.addQuery(query)
        }
        let fetcher = Google_Fetcher<GTLRBatchResult>(service: service, scopes: scopes)
        do {
            return try await Google.executeBatch(batch, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}

//MARK: -Delete
extension Drive {
    func delete(ids:[String]) async throws -> Bool {
        let batch = GTLRBatchQuery()
        for id in ids {
            let query = GTLRDriveQuery_FilesDelete.query(withFileId: id)
            query.supportsAllDrives = true
            batch.addQuery(query)
        }
        let fetcher = Google_Fetcher<GTLRBatchResult>(service: service, scopes: scopes)
        do {
            _ = try await Google.executeBatch(batch, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
    }
}


//MARK: -Labels
extension Drive {
    //MODIFICATIONS
    enum Label_FieldValueType { case date, integer, selection, text, user }
    
    func label<T>(modify fieldID:String, value:T?, valueType:Label_FieldValueType) -> GTLRDrive_LabelFieldModification? {
        let fieldModify = GTLRDrive_LabelFieldModification()
        fieldModify.fieldId = fieldID
        if let value {
            switch valueType {
            case .date:
                if let date = value as? Date,
                   let dt = GTLRDateTime(rfc3339String: date.string(format:.yyyymmdd)) {
                    fieldModify.setDateValues = [dt]
                }
                else if let date = value as? GTLRDateTime {
                    fieldModify.setDateValues = [date]
                } else { print("Unrecognized Date Value: \(value) consider setting the unsetValues to true"); return nil }
            case .integer:
                if let intVal = value as? NSNumber {
                    fieldModify.setIntegerValues = [intVal]
                } else { print("Unrecognized Integer Value: \(value) consider setting the unsetValues to true"); return nil }
            case .selection:
                if let stringValue = value as? String {
                    fieldModify.setSelectionValues = [stringValue]
                } else { print("Unrecognized Selection Value: \(value) consider setting the unsetValues to true"); return nil }
            case .text:
                if let stringValue = value as? String {
                    fieldModify.setTextValues = [stringValue]
                } else { print("Unrecognized Text Value: \(value) consider setting the unsetValues to true"); return nil }
            case .user:
                if let stringValue = value as? String {
                    fieldModify.setUserValues = [stringValue]
                }
                else if let arrayValue = value as? [String], !arrayValue.isEmpty {
                    fieldModify.setUserValues = arrayValue
                }
                else if let arrayValue = value as? [GTLRDrive_User], !arrayValue.isEmpty {
                    fieldModify.setUserValues = arrayValue.compactMap { $0.emailAddress }
                }
                else { fieldModify.unsetValues = true }
            }
        } else {
            fieldModify.unsetValues = true
        }
        return fieldModify
    }
    func label(modify labelID:String, fieldModifications:[GTLRDrive_LabelFieldModification]) -> GTLRDrive_LabelModification {
        let labelMod = GTLRDrive_LabelModification()
        labelMod.labelId = labelID
        labelMod.fieldModifications = fieldModifications
        return labelMod
    }
    func label<T>(modify labelID:String, fieldID:String, value:T?, valueType:Label_FieldValueType, on fileID:String) async throws -> GTLRDrive_ModifyLabelsResponse {
        guard let fieldModification = label(modify: fieldID, value: value, valueType: valueType) else {
            throw Google_Error.didNotProvidePropertiesToMethod(#function)
        }
        let labelModification = label(modify: labelID, fieldModifications: [fieldModification])
        do {
            return try await label(modify: labelID, modifications:[labelModification], on: fileID)
        } catch {
            throw error
        }
    }
    func label(modify labelID:String, modifications:[GTLRDrive_LabelModification], on fileID:String) async throws -> GTLRDrive_ModifyLabelsResponse {
        guard modifications.isNotEmpty, !labelID.isEmpty, !fileID.isEmpty else { throw Google_Error.didNotProvidePropertiesToMethod(#function) }
        let request = GTLRDrive_ModifyLabelsRequest()
        request.labelModifications = modifications
        
        let fetcher = Google_Fetcher<GTLRDrive_ModifyLabelsResponse>(service:service, scopes:scopes)

        let query = GTLRDriveQuery_FilesModifyLabels.query(withObject: request, fileId: fileID)
        do {
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func label(modify labelID:String, modifications:[(mod:[GTLRDrive_LabelModification], fileID:String)]) async throws -> GTLRBatchResult {
        do {
            let batch = GTLRBatchQuery()
            
            for modification in modifications {
                let request = GTLRDrive_ModifyLabelsRequest()
                request.labelModifications = modification.mod
               
                let query = GTLRDriveQuery_FilesModifyLabels.query(withObject: request, fileId: modification.fileID)
                batch.addQuery(query)
            }

            
            let fetcher = Google_Fetcher<GTLRBatchResult>(service:service, scopes:scopes)
            //response is GTLRBatchResult
            return try await Google.execute(batch, fetcher: fetcher)

        } catch {
            throw error
        }
    }
    
    //QUERY
    enum Label_Logic {
        case isNull, isNotNull, isIn, notIn
        case contains, startsWith
        case equal, notEqual, lessThan, greaterThan, lessThanOrEqualsTo, greaterThanOrEqualsTo
        var string : String {
            return switch self {
            case .isNull:
                "is null"
            case .isNotNull:
                "is not null"
            case .isIn:
                "in"
            case .notIn:
                "not in"
            case .contains:
                "contains"
            case .startsWith:
                "starts with"
            case .equal:
                "="
            case .notEqual:
                "!="
            case .lessThan:
                "<"
            case .greaterThan:
                ">"
            case .lessThanOrEqualsTo:
                "<="
            case .greaterThanOrEqualsTo:
                ">="
            }
        }
        func available(fieldType:Label_FieldValueType) -> [Label_Logic] {
            return switch fieldType {
            case .integer, .date:
                [.isNull, .isNotNull, .equal, .notEqual, .lessThan, .greaterThan, .lessThanOrEqualsTo, .greaterThanOrEqualsTo]
            case .selection:
                [.isNull, .isNotNull, .equal, .notEqual, .isIn, .notIn]
            case .text:
                [.isNull, .isNotNull, .equal, .contains, .startsWith]
            case .user:
                [.isNull, .isNotNull, .isIn, .notIn]
            }
        }
    }
    static func labelQuery(labelID:String, fieldID:String, value:String, logic:Label_Logic) -> String {
        "labels/\(labelID).\(fieldID) \(logic.string) '\(value)' and trashed=false"
    }
}



//MARK: -Upload
extension Drive {
    //queries
    private func uploadQuery(url:URL, filename:String? = nil, id:String? = nil, toParentID:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil) -> GTLRDriveQuery_FilesCreate {
        let file = GTLRDrive_File()
        file.name = filename != nil ? filename! + ".\(url.pathExtension)" : url.lastPathComponent
        file.identifier = id
        file.mimeType = url.fileType
        file.descriptionProperty = description
        file.properties = properties
        file.appProperties = appProperties
        file.parents = [toParentID]
        //Not passed in, add so Google Drive knows this information
        file.createdTime   = GTLRDateTime(date:url.dateCreated ?? Date.now)
        file.modifiedTime = GTLRDateTime(date: url.dateModified ?? Date.now)
        
        let parameters = GTLRUploadParameters.init(fileURL: url, mimeType: "")
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: parameters)
        query.supportsAllDrives = true
        query.fields = GTLRDrive_File.queryFileFields
        return query
    }
    private func uploadQuery(data:Data, name:String, type:String,  toParentID:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil) -> GTLRDriveQuery_FilesCreate {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = type
        file.descriptionProperty = description
        file.properties = properties
        file.appProperties = appProperties
        file.parents = [toParentID]

        let parameters = GTLRUploadParameters.init(data: data, mimeType: "")
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: parameters)
        query.supportsAllDrives = true
        
        return query
    }
    fileprivate func totalFilesToUpload(in url:URL) -> Int {
        if url.isDirectory, let enumerator = FileManager.default.enumerator(at: url,
                                                               includingPropertiesForKeys: [.isRegularFileKey],
                                                               options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
               return enumerator.allObjects.count + 1
        } else {
            return 1
        }
    }
   
    //calls
    func upload(url:URL, filename:String? = nil, id:String? = nil, to parentID:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil, progress:((Double) -> ())? = nil) async throws -> GTLRDrive_File{
        let total = Double(totalFilesToUpload(in:url))
        do {
            var runningTotal:Double = 0.0
            var completedUnits = 0.0

            let newFile = try await recursiveUpload(url: url, filename: filename, id: id, to:parentID, description: description, properties: properties, appProperties: appProperties) { update in
                if update == 1 {
                    completedUnits += 1.0
                    runningTotal = completedUnits
                } else {
                    runningTotal = completedUnits + update
                }
                progress?(runningTotal / total)
            }
            return newFile
        } catch {
            throw error
        }
    }
    fileprivate func recursiveUpload(url:URL, filename:String? = nil, id:String? = nil, to parentID:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil, progress:((Double) -> ())? = nil) async throws -> GTLRDrive_File {
        if url.isDirectory {
            let newDirectory = try await create(folder: url.lastPathComponent, in: parentID)
            progress?(1)

            let children = FileManager.contents(directory: url)
            for childURL in children {
               _ = try await recursiveUpload(url: childURL, to: newDirectory.id, progress: progress)
            }
            return newDirectory
        } else {
            let file = try await upload(url: url, filename: filename, id:id, toParentID: parentID, description: description, properties: properties, appProperties: appProperties) { prog in
                progress?(prog)
            }
            return file
        }
    }
    fileprivate func upload(url:URL, filename:String? = nil, id:String? = nil, toParentID:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil, progress:((Double) -> ())? = nil) async throws -> GTLRDrive_File {
        let fetcher = Google_Fetcher<GTLRDrive_File>(service: service, scopes: scopes, progress: progress)
        let query = uploadQuery(url:url,filename:filename, id:id, toParentID: toParentID, description: description, properties: properties, appProperties: appProperties)
        do {
            return try await Google.execute(query, fetcher: fetcher)

        } catch {
            throw error
        }
    }
   
    //Data Upload
    func upload(data:Data, toParentID:String, name:String, type:String, description:String? = nil, properties:GTLRDrive_File_Properties? = nil, appProperties:GTLRDrive_File_AppProperties? = nil, progress:((Double) -> ())? = nil) async throws -> GTLRDrive_File {
        let fetcher = Google_Fetcher<GTLRDrive_File>(service:service, scopes:scopes, progress: progress)
        let query = uploadQuery(data: data, name: name, type: type, toParentID: toParentID, description: description, properties: properties, appProperties: appProperties)
        
        do {
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}


//MARK: -Download
extension Drive {
    ///This uses standard Google.execute method since user is not requesting progress tracking
    ///if progress tracking is reqequested use download(file:to:progress:)
    func download(id:String) async throws -> GTLRDataObject {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId:id)
        let fetcher = Google_Fetcher<GTLRDataObject>(service: service, scopes:scopes, progress: nil)
        do {
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    ///https://github.com/google/google-api-objectivec-client-for-rest/blob/main/Examples/DriveSample/DriveSampleWindowController.m
    ///This does not use the Google.execute method since that does not (to my current understanding), provide a downloadProgress ability (only uploadProgress)
    fileprivate func downloadSessionFetcher(_ file:GTLRDrive_File, to destinationURL:URL?, progress:((Float) -> ())? = nil) -> GTMSessionFetcher {
        var url = "https://www.googleapis.com/drive/v3/files/\(file.id)?alt=media"

        if file.isGoogleType {
            url = file.url.absoluteString + GTLRDrive_File.pdfExt
        }
        let sessionFetcher = service.fetcherService.fetcher(withURLString: url)
        sessionFetcher.destinationFileURL = destinationURL
        if let fileSize = file.size?.floatValue,
           let progress {
            //used when .destinationFileURL is set
            sessionFetcher.downloadProgressBlock = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                let prog = Float(totalBytesWritten) / fileSize
                if (0.0...1.0).contains(prog) {
                    progress(Float(totalBytesWritten) / fileSize)
                }
            }
            //used when downloaded to data
            sessionFetcher.receivedProgressBlock = { bytesWritten, totalBytesWritten  in
                let prog = Float(totalBytesWritten) / fileSize
                if (0.0...1.0).contains(prog) {
                    progress(Float(totalBytesWritten) / fileSize)
                }
            }
        }
        return sessionFetcher
    }
    func download(_ file:GTLRDrive_File, to destinationURL:URL? = nil, progress:((Float) -> ())? = nil) async throws -> Data {
        do {
            guard let user = Google.shared.user else {   throw Google_Error.notLoggedIntoGoogle   }
            _ = try await Google.canProceed(scopes: scopes)

            let service = GTLRDriveService()
            service.authorizer = user.fetcherAuthorizer
                
            let sessionFetcher = downloadSessionFetcher(file, to:destinationURL, progress: progress)
            progress?(0)
            let download = try await sessionFetcher.beginFetch()
            progress?(1)
            return download
        } catch {
            throw error
        }
    }

}
