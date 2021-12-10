//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

struct FileSegmentProtein: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var showFileSource: Bool = false

    var body: some View {
            List {
                // First section hast 64pt padding to account for the
                // space under the segmented control.
                Section(header: Text(NSLocalizedString("Workspace", comment: ""))
                            .padding(.top, 52)
                            .padding(.bottom, 4),
                        content: {
                            WorkspaceRow()
                })
                
                if proteinViewModel.dataSource.files.count != 0 {
                    Section(header: Text(NSLocalizedString("Loaded files", comment: "")).padding(.bottom, 4)) {
                        ForEach(Array(proteinViewModel.dataSource.files.enumerated()), id: \.offset) { index, file in
                            // TO-DO: file size
                            FileRow(fileName: file.fileName,
                                    fileExtension: file.fileExtension,
                                    fileIndex: index,
                                    byteSize: file.byteSize)
                        }
                    }
                }
                    
                Section(header: Text(NSLocalizedString("Loaded models", comment: ""))
                            .padding(.bottom, 4),
                        content: {
                            InfoTextRow(text: NSLocalizedString("Number of proteins:", comment: ""),
                                        value: "\(proteinViewModel.proteinCount)")
                            InfoTextRow(text: NSLocalizedString("Number of subunits:", comment: ""),
                                        value: "\(proteinViewModel.totalSubunitCount)")
                            InfoPopoverRow(label: NSLocalizedString("Number of atoms:", comment: ""),
                                                  value: "\(proteinViewModel.totalAtomCount)",
                                                  isDisabled: proteinViewModel.proteinCount == 0,
                                                  content: { FileAtomElementPopover() })
                })
                
                Section(header: Text(NSLocalizedString("File details", comment: ""))
                            .padding(.bottom, 4),
                        content: {
                    
                            let proteinFile = proteinViewModel.dataSource.files.first
                    
                            InfoTextRow(text: NSLocalizedString("PDB ID:", comment: ""),
                                        value: String(proteinFile?.fileInfo.pdbID ?? "-"))
                            InfoLongTextRow(title: NSLocalizedString("Description: ", comment: ""),
                                        longText: proteinFile?.fileInfo.description)
                            InfoLongTextRow(title: NSLocalizedString("Authors: ", comment: ""),
                                        longText: proteinFile?.fileInfo.authors)
                            Button(NSLocalizedString("View raw file", comment: ""), action: {
                                showFileSource.toggle()
                            })
                            .sheet(isPresented: $showFileSource, onDismiss: nil, content: {
                                let fileSourceViewModel = FileSourceViewModel(fileInfo: proteinFile?.fileInfo)
                                FileSourceView(sourceViewModel: fileSourceViewModel)
                            })
                            .buttonStyle(DefaultButtonStyle())
                            .disabled(proteinViewModel.proteinCount == 0)
                })
                
                Section(header: Text(NSLocalizedString("Remove files", comment: ""))
                            .padding(.bottom, 4),
                        content: {
                            
                            Button(NSLocalizedString("Remove all", comment: ""), action: {
                                proteinViewModel.removeAllFiles()
                            })
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.red)
                            .disabled(proteinViewModel.proteinCount == 0)
                })
            }
            .environment(\.defaultMinListHeaderHeight, 0)
            .listStyle(GroupedListStyle())
    }
}

struct FileSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FileSegmentProtein()
            .environmentObject(ProteinViewModel())
    }
}
