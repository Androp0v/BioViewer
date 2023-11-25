//
//  ProteinRenderTarget.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import Metal
import MetalKit

enum MetalFXUpscalingMode: PickableEnum {
    /// Uses MetalFX temporal upscaling.
    case temporal
    /// Uses MetalFX spatial upscaling.
    case spatial
    /// Doesn't upscale the render with any MetalFX scaling.
    case none
    
    var displayName: String {
        switch self {
        case .temporal:
            return "Temporal"
        case .spatial:
            return "Spatial"
        case .none:
            return "None"
        }
    }
}

class ProteinRenderTarget {
        
    // MARK: - Options
    
    /// Supersampling factor, if you want to perform Super Sampling Anti Aliasing (SSAA).
    var superSamplingCount: Float = 1.0
    /// Upscaling factor used for MetalFX upscaling. Render resolution will be drawable resolution / this factor.
    var metalFXUpscalingFactor: Float = 1.5
    /// The MetalFX upscaling mode. 
    var metalFXUpscalingMode: MetalFXUpscalingMode = .none
    
    // MARK: - Metal layer
    var metalLayer: CAMetalLayer?
    var displayScale: CGFloat = 1.0
    
    // MARK: - Window and texture sizes
    
    private(set) var windowSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    private(set) var renderSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    private(set) var upscaledSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    
    // MARK: - Textures
    
    /// Rendered textures, using `renderSize` resolution.
    private(set) var renderedTextures = ProteinRenderedTextures()
    /// MetalFX upscaled texture.
    private(set) var upscaledTexture = MetalFXUpscaledTexture()
    
    // MARK: - Functions
    
    func updateRenderTarget(for newWindowSize: CGSize, device: MTLDevice) {
        
        self.windowSize = MTLSizeMake(Int(newWindowSize.width), Int(newWindowSize.height), 1)
                
        // Handle MetalFX things
        if metalFXUpscalingMode == .none {
            self.renderSize = MTLSizeMake(
                Int(Float(newWindowSize.width) * superSamplingCount),
                Int(Float(newWindowSize.height) * superSamplingCount),
                1
            )
            self.upscaledSize = MTLSizeMake(
                Int(Float(newWindowSize.width) * superSamplingCount),
                Int(Float(newWindowSize.height) * superSamplingCount),
                1
            )
        } else {
            self.renderSize = MTLSizeMake(
                Int(Float(newWindowSize.width) * superSamplingCount / metalFXUpscalingFactor),
                Int(Float(newWindowSize.height) * superSamplingCount / metalFXUpscalingFactor),
                1
            )
            self.upscaledSize = MTLSizeMake(
                Int(Float(newWindowSize.width) * superSamplingCount),
                Int(Float(newWindowSize.height) * superSamplingCount),
                1
            )
        }
        
        // Update rendered textures
        renderedTextures.makeTextures(
            device: device,
            textureWidth: renderSize.width,
            textureHeight: renderSize.height
        )
        
        // Update the CAMetalLayer, if available
        if let metalLayer {
            // Update the drawable size
            metalLayer.drawableSize = CGSize(
                width: upscaledSize.width,
                height: upscaledSize.height
            )
            // Update content scale
            metalLayer.contentsScale = displayScale * CGFloat(superSamplingCount)
        }
        
        // Early exit if MetalFX Upscaling is not enabled
        if metalFXUpscalingMode != .none {
            // Update MetalFX upscaled texture
            upscaledTexture.makeTexture(
                device: device,
                width: upscaledSize.width,
                height: upscaledSize.height
            )
        }
    }
}
