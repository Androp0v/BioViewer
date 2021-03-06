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
    weak var scene: MetalScene?
    
    var atomsPerConfiguration: Int
    var bondsPerConfiguration: [Int]?
    var bondArrayStarts: [Int]?
    
    var currentConfiguration: Int = 0
    var lastConfiguration: Int
    
    // MARK: - Initialization
    
    init(scene: MetalScene, atomsPerConfiguration: Int, configurationCount: Int) {
        self.scene = scene
        self.atomsPerConfiguration = atomsPerConfiguration
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
        scene?.needsRedraw = true
    }
    
    func nextConfiguration() {
        currentConfiguration += 1
        if currentConfiguration >= lastConfiguration {
            currentConfiguration = 0
        }
        scene?.needsRedraw = true
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
