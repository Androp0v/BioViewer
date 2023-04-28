//
//  AppState.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/6/21.
//

import Foundation
import Metal
import SwiftUI

class AppState: ObservableObject {

    static let shared = AppState()
    
    // MARK: - Configuration
    
    static let maxNumberOfWarnings: Int = 99
    
    // MARK: - Metal support
    
    static let hasSamplerCompareSupport = { () -> Bool in
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        if device.supportsFamily(.common3) {
            return true
        } else {
            return false
        }
    }
    
    static let hasPhotoModeSupport = { () -> Bool in
        
        #if arch(x86_64)
        return false
        #endif
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        if device.supportsFamily(.common3) {
            return true
        } else {
            return false
        }
    }
    
    static let hasMetalFXUpscalingSupport = { () -> Bool in
        
        // Looks like iPhones do not support MetalFX Upscaling
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        // Other Metal 3 capable devices do support MetalFX upscaling
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        if device.supportsFamily(.metal3) {
            return true
        } else {
            return false
        }
    }
    
    static let hasDepthPrePasses = { () -> Bool in
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        if !device.supportsFamily(.apple1) {
            return false
        }
        return true
    }
    
    // MARK: - Version
    
    func version() -> String {
        guard let dictionary = Bundle.main.infoDictionary else { return "" }
        guard let version = dictionary["CFBundleShortVersionString"] as? String else { return "" }
        return version
    }
    
    // MARK: - What's New screen
    
    func shouldShowWhatsNew() -> Bool {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.value(forKey: "userWantsUpdates") == nil {
            userDefaults.set(true, forKey: "userWantsUpdates")
        }
        if userDefaults.value(forKey: "hasSeen\(version())updates") == nil {
            userDefaults.set(false, forKey: "hasSeen\(version())updates")
        }
        
        let userWantsUpdates = userDefaults.bool(forKey: "userWantsUpdates")
        let userHasSeenUpdates = userDefaults.bool(forKey: "hasSeen\(version())updates")
        
        if userWantsUpdates && !userHasSeenUpdates {
            return true
        }
        return false
    }
    
    func userDoesNotWantUpdates() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(false, forKey: "userWantsUpdates")
    }
    
    func userHasSeenWhatsNew() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "hasSeen\(version())updates")
    }
    
    // MARK: - Focused view model
    
    /// Workaround around @FocusedValue bugs
    @Published var focusedViewModel: ProteinViewModel?
}
