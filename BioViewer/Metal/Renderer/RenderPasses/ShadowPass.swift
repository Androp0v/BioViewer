//
//  ShadowPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    func shadowRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, shadowTextures: ShadowTextures) {
    
        // Ensure transparent buffers are loaded
        guard let impostorVertexBuffer = self.impostorVertexBuffer else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures
        shadowRenderPassDescriptor.depthAttachment.texture = shadowTextures.shadowDepthTexture
        shadowRenderPassDescriptor.colorAttachments[0].texture = shadowTextures.shadowTexture
        shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        shadowRenderPassDescriptor.renderTargetWidth = shadowTextures.textureWidth
        shadowRenderPassDescriptor.renderTargetHeight = shadowTextures.textureHeight
        
        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) else {
            return
        }
        
        // Set pipeline state
        guard let shadowRenderingPipelineState = shadowRenderingPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(shadowRenderingPipelineState)
        
        // Set depth state
        renderCommandEncoder.setDepthStencilState(shadowDepthState)
        
        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(impostorVertexBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(subunitBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                             offset: 0,
                                             index: 2)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 3)
        
        renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                               offset: 0,
                                               index: 1)

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
