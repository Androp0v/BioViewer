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
    
    func encodeShadowDepthBoundStage(renderCommandEncoder: MTLRenderCommandEncoder, uniformBuffer: inout MTLBuffer)  {
        
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // MARK: - Depth bound rendering

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
    }
}
