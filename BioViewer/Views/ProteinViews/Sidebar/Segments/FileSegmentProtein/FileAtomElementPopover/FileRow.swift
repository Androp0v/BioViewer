//
//  FileRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct FileRow: View {
    
    let filename: String
    let size: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc")
            VStack(alignment: .leading) {
                Text("Filename.extension")
                    .bold()
                Text(size)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            Spacer()
            Text("PDB")
                .font(.headline)
                .foregroundColor(Color(uiColor: .purple))
        }
    }
}

struct FileRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FileRow(filename: "Filename.extension",
                    size: "3.8 MB")
        }
    }
}
