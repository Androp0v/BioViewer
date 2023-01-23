//
//  FileRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct FileRow: View {
    
    let fileName: String
    let fileExtension: String
    let fileIndex: Int
    let byteSize: Int?
    
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let iconSize: CGFloat = 24
        static let buttonSize: CGFloat = 16
        #else
        static let iconSize: CGFloat = 32
        static let buttonSize: CGFloat = 24
        #endif
    }
    
    public func getBytesString(byteSize: Int) -> String {
        switch byteSize {
        case 0..<1_024:
          return "\(byteSize) bytes"
        case 1_024..<(1_024 * 1_024):
          return "\(String(format: "%.0f", Double(byteSize) / 1024)) KB"
        case 1_024..<(1_024 * 1_024 * 1_024):
          return "\(String(format: "%.1f", Double(byteSize) / 1024 / 1024)) MB"
        case (1_024 * 1_024 * 1_024)...Int.max:
          return "\(String(format: "%.2f", Double(byteSize) / 1024 / 1024)) GB"
        default:
          return "\(byteSize) bytes"
        }
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
                Text(fileName + "." + fileExtension)
                    .bold()
                if let byteSize = byteSize {
                    Text(getBytesString(byteSize: byteSize))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            Spacer()
            // TO-DO: Export files
            /*
            Button(action: {
                // TO-DO
            }, label: {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
            })
                .foregroundColor(.accentColor)
                .buttonStyle(PlainButtonStyle())
            */
            Button(action: {
                proteinDataSource.removeAllFilesFromDatasource()
            }, label: {
                Image(systemName: "trash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
            })
                .foregroundColor(.red)
                .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Previews

struct FileRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FileRow(fileName: "FileName",
                    fileExtension: "pdb",
                    fileIndex: 0,
                    byteSize: 3800)
        }
    }
}
