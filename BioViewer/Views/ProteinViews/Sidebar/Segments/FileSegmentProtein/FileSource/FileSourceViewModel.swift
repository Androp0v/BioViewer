//
//  FileSourceViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/11/21.
//

import Foundation

class FileSourceViewModel: ObservableObject {
    
    /// Batch size for line loading
    let batchSize: Int = 200
    /// Distance to the end of the batch to prefetch next batch
    let prefetchDistance: Int = 50
    /// Number of batches already loaded
    var batchCount: Int = 0
    
    /// All the lines in the source
    var fileInfo: ProteinFileInfo?
    /// Lines currently loaded in the view
    @Published var loadedLines: [String]?
    
    // MARK: - Initialization
    init(fileInfo: ProteinFileInfo?) {
        self.fileInfo = fileInfo
        self.loadedLines = []
        
        guard let fileInfo = fileInfo else {
            return
        }
        guard let sourceLines = fileInfo.sourceLines else {
            return
        }

        loadedLines?.append(contentsOf: sourceLines[0..<min(batchSize, sourceLines.count)])
        batchCount += 1
    }
    
    // MARK: - Public functions
    
    func shouldLoadMore(index: Int) -> Bool {
        return index == batchCount * batchSize - 1 - prefetchDistance
    }
    
    func loadMore() {
        guard let fileInfo = fileInfo else {
            return
        }
        guard let sourceLines = fileInfo.sourceLines else {
            return
        }
        let startRange = batchCount * batchSize
        let endRange = startRange + batchSize
        loadedLines?.append(contentsOf: sourceLines[startRange..<endRange])
        batchCount += 1
    }
    
    func hasWarning(index: Int) -> Bool {
        guard let fileInfo = fileInfo else {
            return false
        }
        if fileInfo.warningIndices.contains(index + 1) {
            return true
        }
        return false
    }
}
