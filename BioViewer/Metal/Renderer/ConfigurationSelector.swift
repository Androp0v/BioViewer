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
    var currentConfiguration: Int = 0
    var lastConfiguration: Int
        
    init(scene: MetalScene, atomsPerConfiguration: Int, lastConfiguration: Int) {
        self.scene = scene
        self.atomsPerConfiguration = atomsPerConfiguration
        self.lastConfiguration = lastConfiguration
    }
    
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
}
