//
//  PhotoModeViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import SwiftUI

@MainActor class PhotoModeViewModel: ObservableObject {
    
    // MARK: - Config
    @Published var photoConfig = PhotoModeConfig()
    @Published var shutterAnimator = ShutterAnimator()
    
    // MARK: - Pickers
    @Published var finalTextureSizeOption: Int = PhotoModeTextureOptions.high {
        didSet {
            switch finalTextureSizeOption {
            case PhotoModeTextureOptions.normal:
                photoConfig.finalTextureSize = 1024
            case PhotoModeTextureOptions.high:
                photoConfig.finalTextureSize = 2048
            case PhotoModeTextureOptions.highest:
                photoConfig.finalTextureSize = 4096
            default:
                photoConfig.finalTextureSize = 2048
            }
        }
    }
    
    @Published var shadowResolution: Int = PhotoModeShadowOptions.high {
        didSet {
            switch finalTextureSizeOption {
            case PhotoModeTextureOptions.normal:
                photoConfig.shadowTextureSize = 2048
            case PhotoModeTextureOptions.high:
                photoConfig.shadowTextureSize = 4096
            case PhotoModeTextureOptions.highest:
                photoConfig.shadowTextureSize = 8192
            default:
                photoConfig.shadowTextureSize = 4096
            }
        }
    }
    
    // MARK: - Viewfinder
    var image: CGImage?
    @Published var isPreviewCreated: Bool = false
    
    // MARK: - Initialization
    init() {
        shutterAnimator.photoModeViewModel = self
    }
}

struct PhotoModeTextureOptions {
    static let normal = 0
    static let high = 1
    static let highest = 2
}

struct PhotoModeShadowOptions {
    static let normal = 0
    static let high = 1
    static let highest = 2
}
