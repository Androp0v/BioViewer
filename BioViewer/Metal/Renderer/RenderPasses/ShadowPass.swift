//
//  ShadowPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    func shadowRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, shadowTextures: ShadowTextures, depthBoundTexture: MTLTexture?, highQuality: Bool) {
    
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures
        shadowRenderPassDescriptor.depthAttachment.texture = shadowTextures.shadowDepthTexture
        shadowRenderPassDescriptor.colorAttachments[0].texture = shadowTextures.shadowTexture
        shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        if AppState.hasDepthUpperBoundPrePass() {
            // colorAttachments[1] is the shadow depth-bound color texture
            shadowRenderPassDescriptor.colorAttachments[1].texture = depthBoundTexture
            // Clear the depth texture using the equivalent to 1.0 (max depth)
            shadowRenderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        shadowRenderPassDescriptor.renderTargetWidth = shadowTextures.textureWidth
        shadowRenderPassDescriptor.renderTargetHeight = shadowTextures.textureHeight
        
        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) else {
            return
        }
        
        // MARK: - Shadow depth bound pass
        
        if AppState.hasDepthUpperBoundPrePass() && self.scene.hasShadows {
            self.encodeShadowDepthBoundStage(renderCommandEncoder: renderCommandEncoder,
                                             uniformBuffer: &uniformBuffer)
        }
        
        // MARK: - Shadow map creation
        
        // Set the correct pipeline state
        var pipelineState: MTLRenderPipelineState?
        if highQuality {
            pipelineState = shadowHQRenderingPipelineState
        } else {
            pipelineState = shadowRenderingPipelineState
        }
        guard let shadowRenderingPipelineState = pipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(shadowRenderingPipelineState)
        
        // Set depth state
        renderCommandEncoder.setDepthStencilState(shadowDepthState)
        
        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.positionBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomWorldCenterBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.billboardMappingBuffer,
                                             offset: 0,
                                             index: 2)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomRadiusBuffer,
                                             offset: 0,
                                             index: 3)
        
        renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                             offset: 0,
                                             index: 4)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 5)
        
        renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                               offset: 0,
                                               index: 0)

        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        guard let indexBufferLength = scene.configurationSelector?.getImpostorIndexBufferRegion().length else {
            return
        }
        guard let indexBufferOffset = scene.configurationSelector?.getImpostorIndexBufferRegion().offset else {
            return
        }
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: indexBufferLength,
                                                   indexType: .uint32,
                                                   indexBuffer: impostorIndexBuffer,
                                                   indexBufferOffset: indexBufferOffset * MemoryLayout<UInt32>.stride)

        renderCommandEncoder.endEncoding()
    }
}
