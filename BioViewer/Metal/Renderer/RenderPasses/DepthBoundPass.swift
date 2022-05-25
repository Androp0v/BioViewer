//
//  DepthBoundPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

import Foundation
import Metal
import QuartzCore
import MetalKit

extension ProteinRenderer {
    
    func depthBoundRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, atomIDTexture: MTLTexture, depthTexture: MTLTexture?) {
        
        // Ensure transparent buffers are loaded
        guard let impostorVertexBuffer = self.impostorVertexBuffer else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        depthBoundRenderPassDescriptor.colorAttachments[0].texture = atomIDTexture
        // Attach depth texture.
        depthBoundRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        depthBoundRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthBoundRenderPassDescriptor) else {
            return
        }
        
        // MARK: - Impostor sphere rendering

        guard let pipelineState = depthBoundRenderPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(pipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(impostorVertexBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 1)
        
        renderCommandEncoder.setFragmentBuffer(disabledAtomsBuffer,
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
        
        // MARK: - End encoding
        renderCommandEncoder.endEncoding()
        
        // FIXME: REMOVE
        /*
        let randomBufferToSwift = disabledAtomsBuffer!.contents().assumingMemoryBound(to: Int16.self)
        let atomCount = disabledAtomsBuffer!.length / MemoryLayout<Int16>.stride
        for i in 0..<atomCount {
            if randomBufferToSwift[i] != 1 {
                print("Enabled atom at \(i)")
            }
        }
        */
    }
}
