//
//  ProteinViewDataSource.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import BioViewerFoundation
import Combine
import Foundation
import simd
import SwiftUI

/// Handle all source data for a `ProteinView` that is not related to the
/// scene nor the appearance, like the `Protein` objects that have been
/// imported or computed values.
@MainActor class ProteinDataSource: ObservableObject {
    
    // MARK: - Properties
    
    /// Total protein count in view.
    @Published var proteinCount: Int = 0
    /// Total subunit count in view.
    @Published var totalChainCount: Int = 0
    /// Total atom count in view.
    @Published var totalAtomCount: Int = 0
    /// Files in the scene.
    private(set) var files: [ProteinFile] = [ProteinFile]() {
        // Run when a new file is added to the datasource
        didSet {
            // FIXME: This is number of files, not proteins
            self.proteinCount = self.files.count
            // Sum all chain counts from all proteins in the datasource
            var newChainCount = 0
            for file in self.files {
                if let proteins = modelsForFile(file: file) {
                    for protein in proteins {
                        newChainCount += protein.chainCount
                    }
                }
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for file in self.files {
                if let proteins = modelsForFile(file: file) {
                    for protein in proteins {
                        newTotalAtomCount += protein.atomCount
                    }
                }
            }
            self.totalChainCount = newChainCount
            self.totalAtomCount = newTotalAtomCount
        }
    }
    /// User-selected model for each ProteinFile.
    @Published var selectedModel = [Int]() {
        didSet {
            Task {
                await updateFileModels(withAnimation: false)
            }
        }
    }
    /// Maps file ID to selected model array index (different files may have different selected models).
    var selectedModelIndexForFile = [ProteinFile: Int]()
    /// The bounding volume of the onscreen proteins.
    var selectionBoundingVolume: BoundingVolume = .zero
        
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - Update Proteins
    
    func updateProteinConnectivity(
        _ connectivity: ProteinConnectivity,
        for protein: Protein
    ) throws {
        if let fileIndex = files.firstIndex(where: { $0.models.contains(protein) }) {
            if let proteinIndex = files[fileIndex].models.firstIndex(of: protein) {
                var updatedProtein = files[fileIndex].models[proteinIndex]
                updatedProtein.bonds = connectivity.computedBonds
                updatedProtein.bondsPerConfiguration = connectivity.computedBondCounts
                updatedProtein.bondsConfigurationArrayStart = connectivity.computedBondConfigurationStarts
                files[fileIndex].models[proteinIndex] = updatedProtein
            }
        }
        throw ProteinDataSourceError.unableToUpdateProteinConnectivity
    }

    // MARK: - Add files
    
    func addProteinFileToDataSource(proteinFile: ProteinFile) async {
        
        guard let proteinViewModel = proteinViewModel else { return }
        
        // Initialize selected protein model to first model.
        selectedModel.append(-1)
        selectedModelIndexForFile[proteinFile] = selectedModel.count - 1
        
        // Add file to datasource.
        files.append(proteinFile)
        await updateFileModels(withAnimation: true)
        
        // Change visualization to trigger rendering
        // TO-DO: visualization should depend on file type too
        Task { @MainActor in
            proteinViewModel.visualizationViewModel?.visualization = .solidSpheres
        }
    }
        
    // MARK: - Remove files
    
    /// Removes file at index from data source and scene.
    func removeFileAtIndex(index: Int) async {
        guard files.count > index else {
            NSLog("File to remove has an index out of bounds.")
            return
        }
        files.remove(at: index)
        await proteinViewModel?.renderer.mutableState.removeBuffers()
    }
    
    /// Removes all files from the data source and the scene.
    func removeAllFilesFromDatasource() async {
        files = []
        selectedModel = []
        selectedModelIndexForFile = [:]
        await proteinViewModel?.renderer.mutableState.removeBuffers()
    }
    
    // MARK: - Update model
    
    func updateFileModels(withAnimation: Bool) async {
        guard let proteinViewModel = self.proteinViewModel,
              let visualizationViewModel = proteinViewModel.visualizationViewModel
        else { return }

        await visualizationViewModel.visualizationBufferLoader.populateVisualizationBuffers(
            visualization: visualizationViewModel.visualization,
            proteinViewModel: proteinViewModel,
            isInitialAnimation: withAnimation
        )
        
        guard let proteins = modelsForFile(file: getFirstFile()) else { return }
        self.selectionBoundingVolume = computeBoundingVolume(proteins: proteins)
        
        // Fit new selection in frustum
        Task {
            await proteinViewModel.renderer.mutableState.fitCameraToBoundingVolume(
                selectionBoundingVolume
            )
        }
    }
        
    func modelsForFile(file: ProteinFile?) -> [Protein]? {
        guard let file = file else {
            return nil
        }
        guard let selectedModelIndex = selectedModelIndexForFile[file] else {
            return nil
        }
        guard selectedModel[selectedModelIndex] < file.models.count else {
            return nil
        }
        if selectedModel[selectedModelIndex] == -1 {
            return file.models
        }
        return [file.models[selectedModel[selectedModelIndex]]]
    }
    
    // FIXME: Remove this function when multiple files are supported
    func getFirstFile() -> ProteinFile? {
        return files.first
    }
    
    // FIXME: Remove this function when multiple files are supported
    func getFirstProtein() -> Protein? {
        return modelsForFile(file: files.first)?.first
    }

}
