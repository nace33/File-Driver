//
//  Drive_Navigator_Inspector.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/25/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct Drive_Navigator_Inspector: View {
    var file : GTLRDrive_File
    
    var body: some View {
        VStack(alignment:.leading, spacing:0) {
            
            Google_Drive_Preview(file: file)
        }
    }
}

#Preview {
    var file : GTLRDrive_File {
        let file = GTLRDrive_File()
        let id = "1FrOhyYMlng_foidAr8IbCY_HS84gbZS3"
        let name = "IMG_1745.mov"
        file.identifier = id
        file.name = name
        //https://drive.google.com/file/d/1FrOhyYMlng_foidAr8IbCY_HS84gbZS3/view?usp=share_link
        return file
    }
    Drive_Navigator_Inspector(file: file)
        .environment(Google.shared)

}
