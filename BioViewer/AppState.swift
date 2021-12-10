//
//  AppState.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/6/21.
//

import Foundation
import Metal

class AppState {

    static let shared = AppState()
    
    // MARK: - Configuration
    static let maxNumberOfWarnings: Int = 99
    
    // MARK: - Metal support
    static func hasSamplerCompareSupport(device: MTLDevice) -> Bool {
        if device.supportsFamily(.common2) || device.supportsFamily(.apple3) || device.supportsFamily(.mac1) || device.supportsFamily(.macCatalyst1) {
            return true
        } else {
            return false
        }
    }
}
