//
//  FileDetailsSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct FileDetailsComponent: View {
    
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    @State var showFileSource: Bool = false
    
    let file: ProteinFile
    
    var body: some View {
        VStack(spacing: .zero) {
            
            VStack {
                // PDB and static XYZ Files
                HStack {
                    InfoTextRow(
                        text: NSLocalizedString("PDB ID:", comment: ""),
                        value: String(file.fileInfo.pdbID ?? "-")
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    Spacer()
                    Text("PDB")
                        .font(.footnote.smallCaps())
                        .padding(.horizontal, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundColor(Color(uiColor: .systemFill))
                        }
                        .padding(.trailing, 4)
                }
                .background(Color(uiColor: .tertiarySystemFill))
            }
            
            Divider()

            VStack(spacing: 4) {
                if file.fileType == .staticStructure {
                    InfoLongTextRow(
                        title: NSLocalizedString("Description: ", comment: ""),
                        longText: file.fileInfo.description
                    )
                    InfoLongTextRow(
                        title: NSLocalizedString("Authors: ", comment: ""),
                        longText: file.fileInfo.authors
                    )
                } else if file.fileType == .dynamicStructure {
                    // Dynamic XYZ Files
                    LineGraphView(values: proteinDataSource.getFirstProtein()?.configurationEnergies)
                }
            }
            .opacity(0.75)
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(uiColor: .secondarySystemFill))
        }
        .mask(RoundedRectangle(cornerRadius: 8))
        
        Button(
            action: {
                withAnimation {
                    showFileSource.toggle()
                }
            }, label: {
                HStack {
                    Image(systemName: "scroll.fill")
                    Text(NSLocalizedString("View raw file", comment: ""))
                }
            }
        )
        .sheet(isPresented: $showFileSource, onDismiss: nil, content: {
            let fileSourceViewModel = FileSourceViewModel(fileInfo: file.fileInfo)
            FileSourceView(sourceViewModel: fileSourceViewModel)
        })
        .buttonStyle(DefaultButtonStyle())
    }
}
