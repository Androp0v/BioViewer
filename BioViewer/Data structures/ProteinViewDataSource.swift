//
//  ProteinViewDataSource.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import Combine
import Foundation
import simd
import SwiftUI

/// Handle all source data for a ```ProteinView``` that is not related to the
/// scene nor the appearance, like the ```Protein``` objects that have been
/// imported or computed values.
class ProteinViewDataSource: ObservableObject {
    
    // MARK: - Properties
    
    /// Files in the scene.
    private(set) var files: [ProteinFile] = [ProteinFile]() {
        // Run when a new file is added to the datasource
        didSet {
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                // FIXME: This is number of files, not proteins
                self.proteinViewModel?.proteinCount = self.files.count
            }
            // Sum all subunit counts from all proteins in the datasource
            var newSubunitCount = 0
            for file in self.files {
                if let protein = modelForFile(file: file) {
                    newSubunitCount += protein.subunitCount
                }
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for file in self.files {
                if let protein = modelForFile(file: file) {
                    newTotalAtomCount += protein.atomCount
                }
            }
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.totalSubunitCount = newSubunitCount
                self.proteinViewModel?.totalAtomCount = newTotalAtomCount
            }
        }
    }
            
    /// Selected user-selected model for each ProteinFile.
    @Published var selectedModel = [Int]() {
        didSet {
            updateFileModels()
        }
    }
    
    /// Maps file ID to selected model array index.
    var selectedModelIndexForFile = [String: Int]()
        
    public weak var proteinViewModel: ProteinViewModel?

    // MARK: - Add files
    
    public func addProteinFileToDataSource(proteinFile: ProteinFile) {
        
        // Initialize selected protein model to first model.
        selectedModel.append(0)
        selectedModelIndexForFile[proteinFile.fileID] = selectedModel.count - 1
        
        // Add file to datasource.
        files.append(proteinFile)
        
        guard let proteinViewModel = proteinViewModel else { return }
        let scene = proteinViewModel.renderer.scene
        guard let protein = modelForFile(file: proteinFile) else { return }
        
        // Add protein configurations to the scene
        scene.createConfigurationSelector(protein: protein)
        
        // Fit file in frustum
        let cameraDistanceToFit = scene.camera.distanceToFitInFrustum(sphereRadius: protein.boundingSphere.radius,
                                                                      aspectRatio: scene.aspectRatio)
        scene.updateCameraDistanceToModel(distanceToModel: cameraDistanceToFit,
                                          proteinDataSource: proteinViewModel.dataSource)
        
        // Change visualization to trigger rendering
        // TO-DO: visualization should depend on file type too
        DispatchQueue.main.async {
            proteinViewModel.visualization = .solidSpheres
        }
        
        // File import finished
        proteinViewModel.statusFinished(action: StatusAction.importFile)
    }
    
    // MARK: - Remove files
    
    /// Removes file at index from data source and scene.
    public func removeFileAtIndex(index: Int) {
        guard files.count > index else {
            NSLog("File to remove has an index out of bounds.")
            return
        }
        files.remove(at: index)
        proteinViewModel?.renderer.removeBuffers()
    }
    
    /// Removes all files from the data source and the scene.
    public func removeAllFilesFromDatasource() {
        files = []
        selectedModel = []
        selectedModelIndexForFile = [:]
        proteinViewModel?.renderer.removeBuffers()
    }
    
    // MARK: - Update model
    
    func updateFileModels() {
        guard let proteinViewModel = self.proteinViewModel else { return }
        proteinViewModel.visualizationBufferLoader.handleVisualizationChange(visualization: proteinViewModel.visualization,
                                                                             proteinViewModel: proteinViewModel)
    }
        
    func modelForFile(file: ProteinFile?) -> Protein? {
        guard let file = file else {
            return nil
        }
        guard let selectedModelIndex = selectedModelIndexForFile[file.fileID] else {
            return nil
        }
        guard selectedModel[selectedModelIndex] < file.models.count else {
            return nil
        }
        return file.models[selectedModel[selectedModelIndex]]
    }
    
    // FIXME: Remove this function when multiple files are supported
    func getFirstProtein() -> Protein? {
        return modelForFile(file: files.first)
    }

}
