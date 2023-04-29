//
//  PointsPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

import Foundation
import Metal

extension ProteinRenderer.MutableState {
    
    #if DEBUG
    func pointsRenderPass(renderer: ProteinRenderer, commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, drawableTexture: MTLTexture, depthTexture: MTLTexture?) {
        
        // Ensure transparent buffers are loaded
        guard let debugPointVertexBuffer = self.debugPointVertexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        renderer.debugPointsRenderPassDescriptor.colorAttachments[0].texture = drawableTexture
        // Clear the drawable texture using the scene's background color
        renderer.debugPointsRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
        // Attach depth texture.
        renderer.debugPointsRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        renderer.debugPointsRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderer.debugPointsRenderPassDescriptor) else {
            return
        }
        
        // MARK: - Point rendering
        guard let debugPointsRenderingPipelineState = renderer.debugPointsRenderingPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(debugPointsRenderingPipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(renderer.depthState)

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
