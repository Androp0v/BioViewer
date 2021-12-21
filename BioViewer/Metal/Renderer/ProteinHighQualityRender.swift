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

extension ProteinRenderer {
    
    func drawHighQualityFrame(size: CGSize, photoModeViewModel: PhotoModeViewModel) throws {
        
        // Create the textures required for HQ rendering
        var hqTextures = HQTextures()
        hqTextures.makeTextures(device: device, photoConfig: photoModeViewModel.photoConfig)
        impostorRenderPassDescriptor.depthAttachment.storeAction = .store
        
        // Create the textures required for HQ shadow casting
        var hqShadowTextures = ShadowTextures()
        hqShadowTextures.makeTextures(device: device,
                                      textureWidth: photoModeViewModel.photoConfig.shadowTextureSize,
                                      textureHeight: photoModeViewModel.photoConfig.shadowTextureSize)
        hqShadowTextures.makeShadowSampler(device: device)
        
        // Create high quality impostor render pass pipeline state
        makeImpostorRenderPipelineState(device: device, variant: .highQuality)
        
        // Change the image aspect ratio
        self.scene.camera.updateProjection(drawableSize: CGSize(width: photoModeViewModel.photoConfig.finalTextureSize,
                                                                height: photoModeViewModel.photoConfig.finalTextureSize))
        let oldAspectRatio = self.scene.aspectRatio
        self.scene.aspectRatio = 1.0
        
        // Assure buffers are loaded
        guard self.subunitBuffer != nil else { throw HQRenderingError.nonLoadedBuffer }
        guard self.atomTypeBuffer != nil else { throw HQRenderingError.nonLoadedBuffer }
        guard let uniformBuffers = self.uniformBuffers else { throw HQRenderingError.nonLoadedBuffer }
        
        // Wait until the inflight command buffer has completed its work
        _ = frameBoundarySemaphore.wait(timeout: .distantFuture)

        // MARK: - Update uniforms buffer
        
        // Ensure the uniform buffer is loaded
        var uniformBuffer = uniformBuffers[currentFrameIndex]
        
        // Update current frame index
        currentFrameIndex = (currentFrameIndex + 1) % maxBuffersInFlight
                
        // Update uniform buffer
        self.scene.updateScene()
        withUnsafePointer(to: self.scene.frameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }
        
        // MARK: - Command buffer & depth
        
        guard let commandQueue = commandQueue else {
            NSLog("Command queue is nil.")
            throw HQRenderingError.unknownError
        }
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            throw HQRenderingError.unknownError
        }
        
        // MARK: - Shadow Map pass
        
        shadowRenderPass(commandBuffer: commandBuffer, uniformBuffer: &uniformBuffer, shadowTextures: hqShadowTextures)
        
        // MARK: - Getting drawable
        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame. Get the drawable as late as possible.
                
        // MARK: - Transparent geometry pass
        impostorRenderPass(commandBuffer: commandBuffer,
                           uniformBuffer: &uniformBuffer,
                           drawableTexture: hqTextures.hqTexture,
                           depthTexture: hqTextures.hqDepthTexture,
                           shadowTextures: hqShadowTextures,
                           variant: .highQuality)
        
        // MARK: - Completion handler
        commandBuffer.addCompletedHandler({ [weak self] commandBuffer in
            guard let self = self else { return }
            // GPU work is complete, signal the semaphore to start the CPU work
            self.frameBoundarySemaphore.signal()
            // Display the image
            DispatchQueue.global(qos: .userInteractive).async {
                photoModeViewModel.shutterAnimator.closeShutter()
            }
            let hqImage = hqTextures.hqTexture.getCGImage(clearBackground: photoModeViewModel.photoConfig.clearBackground,
                                                          depthTexture: hqTextures.hqDepthTexture)
            DispatchQueue.main.async {
                withAnimation {
                    photoModeViewModel.image = hqImage
                    photoModeViewModel.isPreviewCreated = true
                }
            }
            self.scene.aspectRatio = oldAspectRatio
        })
        
        // MARK: - Commit buffer
        // Commit command buffer when the shutter is open (so no animations appear onscreen)
        _ = photoModeViewModel.shutterAnimator.shutterOpenSemaphore.wait(timeout: .distantFuture)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        photoModeViewModel.shutterAnimator.shutterOpenSemaphore.signal()
    }
}
