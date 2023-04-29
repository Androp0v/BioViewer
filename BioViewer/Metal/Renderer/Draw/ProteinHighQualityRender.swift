//
//  ProteinHighQualityRender.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Accelerate
import CoreGraphics
import Foundation
import Metal
import UIKit
import SwiftUI

enum HQRenderingError: Error {
    case nonLoadedBuffer
    case unknownError
}

extension MutableState {
    
    func drawHighQualityFrame(
        renderer: ProteinRenderer,
        size: CGSize,
        photoConfig: PhotoModeConfig,
        photoModeViewModel: PhotoModeViewModel
    ) throws {
        
        // Create the textures required for HQ rendering
        var hqTextures = HQTextures()
        hqTextures.makeTextures(device: device, photoConfig: photoConfig)
        renderer.impostorRenderPassDescriptor.depthAttachment.storeAction = .store
        
        // Create the textures required for HQ depth pre-pass
        var hqPrePassTextures = DepthPrePassTextures()
        hqPrePassTextures.makeTextures(device: device,
                                       textureWidth: photoConfig.finalTextureSize,
                                       textureHeight: photoConfig.finalTextureSize)
        hqPrePassTextures.makeShadowTextures(device: device,
                                             shadowTextureWidth: photoConfig.shadowTextureSize,
                                             shadowTextureHeight: photoConfig.shadowTextureSize)
        
        // Create the textures required for HQ shadow casting
        var hqShadowTextures = ShadowTextures()
        hqShadowTextures.makeTextures(
            device: device,
            textureWidth: photoConfig.shadowTextureSize,
            textureHeight: photoConfig.shadowTextureSize
        )
        hqShadowTextures.makeShadowSampler(device: device)
        
        // Create high quality shadow render pass pipeline state
        renderer.makeShadowRenderPipelineState(device: device, highQuality: true)

        // Create high quality impostor render pass pipeline state
        switch scene.currentVisualization {
        case .solidSpheres:
            renderer.makeImpostorRenderPipelineState(device: device, variant: .solidSpheresHQ)
        case .ballAndStick:
            renderer.makeImpostorRenderPipelineState(device: device, variant: .ballAndSticksHQ)
        }
        
        // Change the image aspect ratio
        scene.camera.updateProjection(drawableSize: CGSize(
            width: photoConfig.finalTextureSize,
            height: photoConfig.finalTextureSize
        ))
        let oldAspectRatio = scene.aspectRatio
        scene.aspectRatio = 1.0
        
        // Assure buffers are loaded
        guard self.atomElementBuffer != nil else { throw HQRenderingError.nonLoadedBuffer }
        guard let uniformBuffers = self.uniformBuffers else { throw HQRenderingError.nonLoadedBuffer }
        
        // Wait until the inflight command buffer has completed its work
        _ = renderer.frameBoundarySemaphore.wait(timeout: .distantFuture)
        
        // MARK: - Update uniforms buffer
        
        // Ensure the uniform buffer is loaded
        var uniformBuffer = uniformBuffers[currentFrameIndex]
        
        // Update current frame index
        currentFrameIndex = (currentFrameIndex + 1) % renderer.maxBuffersInFlight
                
        // Update uniform buffer
        scene.updateScene()
        withUnsafePointer(to: scene.currentFrameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }
        
        // MARK: - Command buffer & depth
        
        guard let commandQueue = renderer.commandQueue else {
            NSLog("Command queue is nil.")
            throw HQRenderingError.unknownError
        }
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            throw HQRenderingError.unknownError
        }
        
        // MARK: - Shadow Map pass
        
        shadowRenderPass(
            renderer: renderer,
            commandBuffer: commandBuffer,
            uniformBuffer: &uniformBuffer,
            shadowTextures: hqShadowTextures,
            shadowDepthPrePassTexture: hqPrePassTextures.shadowColorTexture,
            highQuality: true
        )
        
        // MARK: - Getting drawable
        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame. Get the drawable as late as possible.
                
        // MARK: - Transparent geometry pass
        impostorRenderPass(
            renderer: renderer,
            commandBuffer: commandBuffer,
            uniformBuffer: &uniformBuffer,
            drawableTexture: hqTextures.hqTexture,
            depthTexture: hqTextures.hqDepthTexture,
            depthPrePassTexture: hqPrePassTextures.colorTexture,
            shadowTextures: hqShadowTextures,
            variant: .solidSpheresHQ,
            renderBonds: scene.currentVisualization == .ballAndStick
        )
        
        // MARK: - Completion handler
        commandBuffer.addCompletedHandler({ _ in
            // GPU work is complete, signal the semaphore to start the CPU work
            renderer.frameBoundarySemaphore.signal()
            // Display the image
            Task { @MainActor in
                photoModeViewModel.shutterAnimator.closeShutter()
            }
            let hqImage = hqTextures.hqTexture.getCGImage(
                clearBackground: photoConfig.clearBackground,
                depthTexture: hqTextures.hqDepthTexture
            )
            Task { @MainActor in
                withAnimation {
                    photoModeViewModel.image = hqImage
                    photoModeViewModel.isPreviewCreated = true
                }
            }
            self.scene.aspectRatio = oldAspectRatio
        })
        
        // MARK: - Commit buffer
        // Commit command buffer when the shutter is open (so no animations appear onscreen)
        Task { @MainActor in
            _ = photoModeViewModel.shutterAnimator.shutterOpenSemaphore.wait(timeout: .distantFuture)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            photoModeViewModel.shutterAnimator.shutterOpenSemaphore.signal()
        }
    }
}
