//
//  DepthBoundShadowPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/6/22.
//

import Foundation
import Metal
import QuartzCore
import MetalKit

extension ProteinRenderer {
    
    func depthBoundShadowRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, colorTexture: MTLTexture, depthTexture: MTLTexture?) {
        
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        shadowDepthBoundRenderPassDescriptor.colorAttachments[0].texture = colorTexture
        // Attach depth texture.
        shadowDepthBoundRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        shadowDepthBoundRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowDepthBoundRenderPassDescriptor) else {
            return
        }
        
        // MARK: - Impostor sphere rendering

        guard let pipelineState = shadowDepthBoundRenderPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(pipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(shadowDepthState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.positionBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomWorldCenterBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 2)
        
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
        
        // MARK: - End encoding
        renderCommandEncoder.endEncoding()
    }
}
