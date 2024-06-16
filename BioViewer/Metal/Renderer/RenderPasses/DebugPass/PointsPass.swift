//
//  PointsPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    #if DEBUG
    func pointsRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, drawableTexture: MTLTexture, depthTexture: MTLTexture?) {
        
        // Ensure transparent buffers are loaded
        guard let debugPointVertexBuffer = self.debugPointVertexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        Self.debugPointsRenderPassDescriptor.colorAttachments[0].texture = drawableTexture
        // Clear the drawable texture using the scene's background color
        Self.debugPointsRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
        // Attach depth texture.
        Self.debugPointsRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        Self.debugPointsRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: Self.debugPointsRenderPassDescriptor) else {
            return
        }
        
        // MARK: - Point rendering
        guard let debugPointsRenderingPipelineState = debugPointsRenderingPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(debugPointsRenderingPipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(debugPointVertexBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 1)
        
        renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                               offset: 0,
                                               index: 1)

        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.none)

        // Draw primitives
        renderCommandEncoder.drawPrimitives(type: .point,
                                            vertexStart: 0,
                                            vertexCount: debugPointVertexBuffer.length / MemoryLayout<DebugPoint>.stride)
                
        // MARK: - End encoding
        renderCommandEncoder.endEncoding()
    }
    #endif
}
