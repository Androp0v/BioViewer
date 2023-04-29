//
//  ShadowPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal

extension ProteinRenderer.MutableState {
    
    func shadowRenderPass(renderer: ProteinRenderer, commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, shadowTextures: ShadowTextures, shadowDepthPrePassTexture: MTLTexture?, highQuality: Bool) {
    
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures
        renderer.shadowRenderPassDescriptor.depthAttachment.texture = shadowTextures.shadowDepthTexture
        renderer.shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderer.shadowRenderPassDescriptor.colorAttachments[0].texture = shadowTextures.shadowTexture
        if AppState.hasDepthPrePasses() {
            // colorAttachments[1] is the shadow depth pre-pass texture
            renderer.shadowRenderPassDescriptor.colorAttachments[1].texture = shadowDepthPrePassTexture
            // Clear the depth texture using the equivalent to 1.0 (max depth)
            renderer.shadowRenderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        renderer.shadowRenderPassDescriptor.renderTargetWidth = shadowTextures.textureWidth
        renderer.shadowRenderPassDescriptor.renderTargetHeight = shadowTextures.textureHeight
        
        // MARK: - Render command
        
        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderer.shadowRenderPassDescriptor) else {
            return
        }
        renderCommandEncoder.label = "Shadow Depth Pre-pass & Shadow Map Generation"
        
        // Set depth state
        renderCommandEncoder.setDepthStencilState(renderer.shadowDepthState)
        
        // MARK: - Shadow depth pre-pass
        
        if AppState.hasDepthPrePasses() && scene.hasShadows {
            self.encodeShadowDepthPrePassStage(
                renderer: renderer,
                renderCommandEncoder: renderCommandEncoder,
                uniformBuffer: &uniformBuffer
            )
        } else {
            // Add buffers to pipeline
            renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.positionBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomWorldCenterBuffer,
                                                 offset: 0,
                                                 index: 1)
            renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                                 offset: 0,
                                                 index: 4)
        }
        
        // MARK: - Shadow map creation
        
        // Set the correct pipeline state
        var pipelineState: MTLRenderPipelineState?
        if highQuality {
            pipelineState = renderer.shadowHQRenderingPipelineState
        } else {
            pipelineState = renderer.shadowRenderingPipelineState
        }
        guard let shadowRenderingPipelineState = pipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(shadowRenderingPipelineState)
        
        // Add other buffers to the render command
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.billboardMappingBuffer,
                                             offset: 0,
                                             index: 2)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomRadiusBuffer,
                                             offset: 0,
                                             index: 3)
        
        renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                               offset: 0,
                                               index: 0)

        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        guard let configurationSelector = scene.configurationSelector else {
            return
        }
        let indexBufferRegion = configurationSelector.getImpostorIndexBufferRegion()
        
        renderCommandEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexBufferRegion.length,
            indexType: .uint32,
            indexBuffer: impostorIndexBuffer,
            indexBufferOffset: indexBufferRegion.offset * MemoryLayout<UInt32>.stride
        )

        renderCommandEncoder.endEncoding()
    }
}
