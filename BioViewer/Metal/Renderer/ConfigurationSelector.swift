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
    var atomsPerConfiguration: Int
    var currentConfiguration: Int = 0
        
    init(atomsPerConfiguration: Int) {
        self.atomsPerConfiguration = atomsPerConfiguration
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
