//
//  ImpostorPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal
import QuartzCore
import MetalKit

extension ProteinRenderer {
    
    func impostorRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, drawableTexture: MTLTexture, depthTexture: MTLTexture?) {
        
        // Ensure transparent buffers are loaded
        guard let impostorVertexBuffer = self.impostorVertexBuffer else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        impostorRenderPassDescriptor.colorAttachments[0].texture = drawableTexture
        // Clear the drawable texture using the scene's background color
        impostorRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
        // Attach depth texture.
        impostorRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        impostorRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: impostorRenderPassDescriptor) else {
            return
        }

        // Set pipeline state
        guard let impostorRenderingPipelineState = impostorRenderingPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(impostorRenderingPipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)

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
        renderCommandEncoder.setFragmentTexture(shadowTextures.shadowDepthTexture,
                                                index: 0)
        renderCommandEncoder.setFragmentSamplerState(shadowTextures.shadowSampler,
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
