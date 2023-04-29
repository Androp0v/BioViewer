//
//  ConfigurationSelector.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/12/21.
//

import Foundation

struct BufferRegion {
    let length: Int
    let offset: Int
}

class ConfigurationSelector {
    var proteins: [Protein]
    
    var atomsPerConfiguration: Int
    
    var subunitIndices: [Int]
    var subunitLengths: [Int]
    
    var bondsPerConfiguration: [Int]?
    var bondArrayStarts: [Int]?
    
    var currentConfiguration: Int = 0
    var lastConfiguration: Int
    
    // MARK: - Initialization
    
    init(for proteins: [Protein], atomsPerConfiguration: Int, subunitIndices: [Int], subunitLengths: [Int], configurationCount: Int) {
        self.proteins = proteins
        self.atomsPerConfiguration = atomsPerConfiguration
        self.subunitIndices = subunitIndices
        self.subunitLengths = subunitLengths
        self.lastConfiguration = configurationCount - 1
    }
    
    func addBonds(bondsPerConfiguration: [Int], bondArrayStarts: [Int]) {
        self.bondsPerConfiguration = bondsPerConfiguration
        self.bondArrayStarts = bondArrayStarts
    }
    
    // MARK: - Change configuration
    
    func previousConfiguration() {
        currentConfiguration -= 1
        if currentConfiguration <= -1 {
            currentConfiguration = lastConfiguration
        }
    }
    
    func nextConfiguration() {
        currentConfiguration += 1
        if currentConfiguration >= lastConfiguration {
            currentConfiguration = 0
        }
    }
    
    // MARK: - Get buffer regions
    
    func getImpostorVertexBufferRegion() -> BufferRegion {
        return BufferRegion(length: atomsPerConfiguration * 4,
                            offset: atomsPerConfiguration * 4 * currentConfiguration)
    }
        
    func getImpostorIndexBufferRegion() -> BufferRegion {
        return BufferRegion(length: atomsPerConfiguration * 2 * 3,
                            offset: atomsPerConfiguration * 2 * 3 * currentConfiguration)
    }
        
    func getBondsIndexBufferRegion() -> BufferRegion? {
        guard let bondsPerConfiguration = bondsPerConfiguration else { return nil }
        guard let bondArrayStarts = bondArrayStarts else { return nil }
        return BufferRegion(length: bondsPerConfiguration[currentConfiguration] * 8 * 3,
                            offset: bondArrayStarts[currentConfiguration] * 8 * 3)
    }
}
