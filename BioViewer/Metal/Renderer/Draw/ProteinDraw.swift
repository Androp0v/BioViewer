//
//  ProteinDraw.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/4/23.
//

import Foundation
import MetalKit

extension MutableState {
    
    func drawFrame(from renderer: ProteinRenderer, in layer: CAMetalLayer) {
        // Check if the scene needs to be redrawn.
        guard scene.needsRedraw || scene.isPlaying else {
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
        scene.updateScene()
        let currentFrameData = scene.currentFrameData
        let lastFrameFrameData = scene.lastFrameFrameData
        let reprojectionData = scene.reprojectionData(
            currentFrameData: currentFrameData,
            oldFrameData: lastFrameFrameData
        )
        withUnsafePointer(to: currentFrameData) {
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
        
        if scene.lastColorPassRequest > scene.lastColorPass {
            self.fillColorPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                colorBuffer: self.atomColorBuffer,
                colorFill: scene.colorFill
            )
        }
        
        /*- RENDER PASSES -*/
        
        // MARK: - Shadow Map pass
        
        if scene.hasShadows {
            self.shadowRenderPass(
                renderer: renderer,
                commandBuffer: commandBuffer, uniformBuffer: &uniformBuffer,
                shadowTextures: shadowTextures,
                shadowDepthPrePassTexture: depthPrePassTextures.shadowColorTexture,
                highQuality: false
            )
        }
        
        var viewTexture: MTLTexture?
        var viewDepthTexture: MTLTexture?
        if !renderer.isBenchmark {
            viewTexture = renderTarget.renderedTextures.colorTexture
            viewDepthTexture = renderTarget.renderedTextures.depthTexture
        } else {
            viewTexture = benchmarkTextures.colorTexture
            viewDepthTexture = benchmarkTextures.depthTexture
        }
        
        if let viewTexture, let viewDepthTexture {
            
            // MARK: - Impostor pass
            
            self.impostorRenderPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                uniformBuffer: &uniformBuffer,
                drawableTexture: viewTexture,
                depthTexture: viewDepthTexture,
                depthPrePassTexture: depthPrePassTextures.colorTexture,
                shadowTextures: shadowTextures,
                variant: .solidSpheres,
                renderBonds: scene.currentVisualization == .ballAndStick
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
            
            // MARK: - Shadow blurring
            /*
            self.shadowBlurPass(
                renderer: renderer,
                commandBuffer: commandBuffer,
                texture: viewTexture
            )
             */
            
            // MARK: - Get drawable
            // The final pass can only render if a drawable is available, otherwise it needs to skip
            // rendering this frame. Get the drawable as late as possible.
            var drawable: CAMetalDrawable?
            if !renderer.isBenchmark {
                drawable = layer.nextDrawable()
                if let drawable {
                    
                    // MARK: - MetalFX Upscaling

                    if renderTarget.metalFXUpscalingMode != .none {
                        self.metalFXUpscaling(
                            renderer: renderer,
                            commandBuffer: commandBuffer,
                            sourceTexture: viewTexture,
                            depthTexture: viewDepthTexture,
                            motionTexture: renderTarget.renderedTextures.motionTexture, // TODO: High-quality, others
                            outputTexture: renderTarget.upscaledTexture.upscaledColor,
                            reprojectionData: reprojectionData
                        )
                        self.copyToDrawable(
                            commandBuffer: commandBuffer,
                            finalRenderedTexture: renderTarget.upscaledTexture.upscaledColor,
                            drawableTexture: drawable.texture
                        )
                    } else {
                        self.copyToDrawable(
                            commandBuffer: commandBuffer,
                            finalRenderedTexture: renderTarget.renderedTextures.colorTexture,
                            drawableTexture: drawable.texture
                        )
                    }
                    
                    // MARK: - Present drawable
                    
                    commandBuffer.present(drawable)
                    
                    // Schedule a drawable presentation to occur after the GPU completes its work
                    // commandBuffer.present(drawable, afterMinimumDuration: averageGPUTime)
                }
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
