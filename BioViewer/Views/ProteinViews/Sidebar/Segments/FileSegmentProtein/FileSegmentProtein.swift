//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI
import simd

struct FileSegmentProtein: View {

    @EnvironmentObject var proteinDataSource: ProteinDataSource
    
    private func getModelNames(modelCount: Int) -> [String] {
        var modelNames = [String]()
        modelNames.append(NSLocalizedString("Show all", comment: ""))
        for modelIndex in 0..<modelCount {
            modelNames.append( NSLocalizedString("Model \(modelIndex + 1)", comment: ""))
        }
        return modelNames
    }

    var body: some View {
        List {
            
            // MARK: - Loaded files
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(
                header: Text(NSLocalizedString("Loaded files", comment: ""))
                        .padding(.bottom, 4)
            ) {
                if proteinDataSource.files.count == 0 {
                    EmptyDataRow(text: NSLocalizedString("No imported files", comment: ""))
                } else {
                    ForEach(Array(proteinDataSource.files.enumerated()), id: \.offset) { index, file in
                        FileRow(
                            fileName: file.fileName,
                            fileExtension: file.fileExtension,
                            fileIndex: index,
                            byteSize: file.byteSize
                        )
                        
                        // Show model selector only if there's more than one model
                        if file.models.count > 1 {
                            LegacyPickerRow(
                                optionName: NSLocalizedString("Model", comment: ""),
                                selectedOption: $proteinDataSource.selectedModel[index],
                                startIndex: -1,
                                pickerOptions: getModelNames(modelCount: file.models.count)
                            )
                        }
                        
                        if let proteins = proteinDataSource.modelsForFile(file: file) {
                            InfoTextRow(
                                text: NSLocalizedString("Number of chains:", comment: ""),
                                value: "\(proteins.reduce(0) { $0 + $1.chainCount })"
                            )
                            InfoAtomsRow(
                                label: NSLocalizedString("Number of atoms:", comment: ""),
                                value: proteins.reduce(0) { $0 + $1.elementComposition.totalCount },
                                isDisabled: false,
                                file: file
                            )
                        }
                        
                        FileDetailsComponent(file: file)
                    }
                }
            }
            #if targetEnvironment(macCatalyst)
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            #endif
                
            // MARK: - Loaded models
            /*
            Section(header: Text(NSLocalizedString("Loaded models", comment: "")).padding(.bottom, 4)) {
                
                InfoTextRow(text: NSLocalizedString("Number of proteins:", comment: ""),
                            value: "\(proteinViewModel.proteinCount)")
            }
            */
            
            // MARK: - Remove files
            Section(header: Text(NSLocalizedString("Remove files", comment: ""))
                        .padding(.bottom, 4),
                    content: {
                        
                        Button(NSLocalizedString("Remove all", comment: ""), action: {
                            Task {
                                await proteinDataSource.proteinViewModel?.removeAllFiles()
                            }
                        })
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.red)
                        .disabled(proteinDataSource.proteinCount == 0)
            })
            #if targetEnvironment(macCatalyst)
            .listRowInsets(EdgeInsets(top: .zero, leading: 12, bottom: .zero, trailing: 12))
            #endif
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(DefaultListStyle())
    }
}

struct FileSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FileSegmentProtein()
            .environmentObject(ProteinViewModel())
    }
}
