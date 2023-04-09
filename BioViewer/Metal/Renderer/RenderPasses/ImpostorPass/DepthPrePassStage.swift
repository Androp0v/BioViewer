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

extension ProteinRenderer.MutableState {
    
    func encodeDepthBoundStage(renderer: ProteinRenderer, renderCommandEncoder: MTLRenderCommandEncoder, uniformBuffer: inout MTLBuffer) {
        
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // MARK: - Impostor sphere rendering

        guard let pipelineState = renderer.depthPrePassRenderPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(pipelineState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(
            billboardVertexBuffers.positionBuffer,
            offset: 0,
            index: 0
        )
        renderCommandEncoder.setVertexBuffer(
            billboardVertexBuffers.atomWorldCenterBuffer,
            offset: 0,
            index: 1
        )
        renderCommandEncoder.setVertexBuffer(
            uniformBuffer,
            offset: 0,
            index: 5
        )
        
        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        guard let configurationSelector = renderer.scene.configurationSelector else {
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
    }
}
