//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI
import simd

struct FileSegmentProtein: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    private func getModelNames(modelCount: Int) -> [String] {
        var modelNames = [String]()
        for modelIndex in 0..<modelCount {
            modelNames.append( NSLocalizedString("Model \(modelIndex + 1)", comment: ""))
        }
        return modelNames
    }

    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            /*
            Section(header: Text(NSLocalizedString("Workspace", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4),
                    content: {
                        WorkspaceRow()
            })
            */
            
            // MARK: - Loaded files
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("Loaded files", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4)) {
                if proteinViewModel.dataSource.files.count == 0 {
                    EmptyFileRow()
                } else {
                    ForEach(Array(proteinViewModel.dataSource.files.enumerated()), id: \.offset) { index, file in
                        FileRow(fileName: file.fileName,
                                fileExtension: file.fileExtension,
                                fileIndex: index,
                                byteSize: file.byteSize)
                        
                        // Show model selector only if there's more than one model
                        if file.models.count > 1 {
                            PickerRow(optionName: NSLocalizedString("Viewing:", comment: ""),
                                      selectedOption: $proteinViewModel.dataSource.selectedModel[index],
                                      pickerOptions: getModelNames(modelCount: file.models.count))
                                .listRowSeparator(.hidden)
                        }
                        
                        if let protein = proteinViewModel.dataSource.modelForFile(file: file) {
                            
                            InfoTextRow(text: NSLocalizedString("Number of subunits:", comment: ""),
                                        value: "\(protein.subunitCount)")
                                .listRowSeparator(.hidden)
                            InfoAtomsRow(label: NSLocalizedString("Number of atoms:", comment: ""),
                                         value: "\(protein.atomCount)",
                                         isDisabled: false,
                                         file: file)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
                
            // MARK: - Loaded models
            /*
            Section(header: Text(NSLocalizedString("Loaded models", comment: "")).padding(.bottom, 4)) {
                
                InfoTextRow(text: NSLocalizedString("Number of proteins:", comment: ""),
                            value: "\(proteinViewModel.proteinCount)")
            }
            */
            
            // MARK: - File details
            Section(header: Text(NSLocalizedString("File details", comment: ""))
                        .padding(.bottom, 4),
                    content: {
                        FileDetailsSection()
            })
            
            // MARK: - Remove files
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
