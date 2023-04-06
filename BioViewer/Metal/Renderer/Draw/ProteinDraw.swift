//
//  ProteinDraw.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/4/23.
//

import Foundation
import MetalKit

extension ProteinRenderer.MutableState {
    
    @MainActor func drawFrame(from renderer: ProteinRenderer, in view: MTKView) {
        // Check if the scene needs to be redrawn.
        guard renderer.scene.needsRedraw || renderer.scene.isPlaying else {
            return
        }
                
        // Assure buffers are loaded
        guard atomElementBuffer != nil,
              atomColorBuffer != nil,
              let uniformBuffers = uniformBuffers
        else {
            return
        }
        
        // Wait until the inflight command buffer has completed its work.
        _ = renderer.frameBoundarySemaphore.wait(timeout: .distantFuture)
        
        // MARK: - Update uniforms buffer
        
        // Ensure the uniform buffer is loaded
        var uniformBuffer = uniformBuffers[self.currentFrameIndex]
        
        // Update current frame index
        self.currentFrameIndex = (self.currentFrameIndex + 1) % renderer.maxBuffersInFlight
                
        // Update uniform buffer
        renderer.scene.updateScene()
        withUnsafePointer(to: renderer.scene.frameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }
        
        // MARK: - Command buffer & queue
        
        guard let commandQueue = renderer.commandQueue else {
            NSLog("Command queue is nil.")
            return
        }
                
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            return
        }
        
        /*- COMPUTE PASSES -*/
        
        // MARK: - Fill color pass
        
        if renderer.scene.lastColorPassRequest > renderer.scene.lastColorPass {
            self.fillColorPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                colorBuffer: self.atomColorBuffer,
                colorFill: renderer.scene.colorFill
            )
        }
        
        /*- RENDER PASSES -*/
        
        // MARK: - Shadow Map pass
        
        if renderer.scene.hasShadows {
            self.shadowRenderPass(
                renderer: renderer,
                commandBuffer: commandBuffer, uniformBuffer: &uniformBuffer,
                shadowTextures: renderer.shadowTextures,
                shadowDepthPrePassTexture: renderer.depthPrePassTextures.shadowColorTexture,
                highQuality: false
            )
        }
        
        // GETTING THE DRAWABLE
        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame. Get the drawable as late as possible.
        var viewTexture: MTLTexture?
        var viewDepthTexture: MTLTexture?
        var drawable: CAMetalDrawable?
        if !renderer.isBenchmark {
            drawable = view.currentDrawable
            viewTexture = view.currentDrawable?.texture
            viewDepthTexture = view.depthStencilTexture
        } else {
            viewTexture = renderer.benchmarkTextures.colorTexture
            viewDepthTexture = renderer.benchmarkTextures.depthTexture
        }
        
        if let viewTexture, let viewDepthTexture {
            // MARK: - Impostor pass
            
            self.impostorRenderPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                uniformBuffer: &uniformBuffer,
                drawableTexture: viewTexture,
                depthTexture: viewDepthTexture,
                depthPrePassTexture: renderer.depthPrePassTextures.colorTexture,
                shadowTextures: renderer.shadowTextures,
                variant: .solidSpheres,
                renderBonds: renderer.scene.currentVisualization == .ballAndStick
            )
                                            
            // MARK: - Debug points pass
            #if DEBUG
            self.pointsRenderPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                uniformBuffer: &uniformBuffer,
                drawableTexture: viewTexture,
                depthTexture: viewDepthTexture
            )
            #endif
            
            // Schedule a drawable presentation to occur after the GPU completes its work
            // commandBuffer.present(drawable, afterMinimumDuration: averageGPUTime)
            if let drawable {
                commandBuffer.present(drawable)
            }
        }
        
        // MARK: - Triple buffering
        
        commandBuffer.addCompletedHandler({ commandBuffer in
            // Store the time required to render the frame
            renderer.lastFrameGPUTime = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
            if renderer.isBenchmark,
               renderer.benchmarkedFrames < BioBenchConfig.numberOfFrames {
                renderer.benchmarkTimes?[renderer.benchmarkedFrames] = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
                renderer.benchmarkedFrames += 1
            }
            // GPU work is complete, signal the semaphore to start the CPU work
            renderer.frameBoundarySemaphore.signal()
        })
        
        // MARK: - Commit buffer
        // Commit command buffer
        commandBuffer.commit()        
    }
}
