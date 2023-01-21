//
//  FileDetailsSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct FileDetailsComponent: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
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
                }
                .background(Color(uiColor: .tertiarySystemFill))
            }
            
            Divider()

            VStack {
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
                    LineGraphView(values: proteinViewModel.dataSource.getFirstProtein()?.configurationEnergies)
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