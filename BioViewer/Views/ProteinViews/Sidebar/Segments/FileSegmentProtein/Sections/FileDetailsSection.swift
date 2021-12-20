//
//  FileDetailsSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct FileDetailsSection: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var showFileSource: Bool = false
    
    var body: some View {
        let proteinFile = proteinViewModel.dataSource.files.first
        
        if proteinFile?.fileType == .staticStructure {
            // PDB and static XYZ Files
            InfoTextRow(text: NSLocalizedString("PDB ID:", comment: ""),
                        value: String(proteinFile?.fileInfo.pdbID ?? "-"))
            InfoLongTextRow(title: NSLocalizedString("Description: ", comment: ""),
                        longText: proteinFile?.fileInfo.description)
            InfoLongTextRow(title: NSLocalizedString("Authors: ", comment: ""),
                        longText: proteinFile?.fileInfo.authors)
        } else if proteinFile?.fileType == .dynamicStructure {
            // Dynamic XYZ Files
            LineGraphView(values: proteinViewModel.dataSource.files.first?.protein.configurationEnergies)
        }
        Button(NSLocalizedString("View raw file", comment: ""), action: {
            showFileSource.toggle()
        })
        .sheet(isPresented: $showFileSource, onDismiss: nil, content: {
            let fileSourceViewModel = FileSourceViewModel(fileInfo: proteinFile?.fileInfo)
            FileSourceView(sourceViewModel: fileSourceViewModel)
        })
        .buttonStyle(DefaultButtonStyle())
        .disabled(proteinViewModel.proteinCount == 0)
    }
}

struct FileDetailsSection_Previews: PreviewProvider {
    static var previews: some View {
        FileDetailsSection()
            .environmentObject(ProteinViewModel())
    }
}
