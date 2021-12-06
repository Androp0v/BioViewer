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
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let iconSize: CGFloat = 24
        #else
        static let iconSize: CGFloat = 32
        #endif
    }
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: "doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                /*Text("PDB")
                    .font(.headline)
                    .foregroundColor(.accentColor)*/
            }
            VStack(alignment: .leading) {
                Text("Filename.extension")
                    .bold()
                Text(size)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            Spacer()
            Button(action: {
                // TO-DO
            }, label: {
                Image(systemName: "trash")
            })
                .foregroundColor(.red)
                .buttonStyle(PlainButtonStyle())
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
