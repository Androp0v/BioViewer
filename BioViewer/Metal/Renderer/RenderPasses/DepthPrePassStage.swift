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
    
    func encodeDepthBoundStage(renderCommandEncoder: MTLRenderCommandEncoder, uniformBuffer: inout MTLBuffer) {
        
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // MARK: - Impostor sphere rendering

        guard let pipelineState = depthPrePassRenderPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(pipelineState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.positionBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(billboardVertexBuffers.atomWorldCenterBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 5)
        
        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        guard let configurationSelector = scene.configurationSelector else {
            return
        }
        if false {
            let indexBufferRegion = configurationSelector.getImpostorIndexBufferRegion()
            renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                       indexCount: indexBufferRegion.length,
                                                       indexType: .uint32,
                                                       indexBuffer: impostorIndexBuffer,
                                                       indexBufferOffset: indexBufferRegion.offset * MemoryLayout<UInt32>.stride)
        } else {
            var subunitID = 0
            for indexBufferRegion in configurationSelector.getSubunitSplitImpostorIndexBufferRegions() {
                let subunitIDList = [282, 348, 114, 66, 236, 230, 224, 212, 218, 180, 216, 222, 228, 234, 210, 226, 214, 232, 238, 220, 352, 70, 118, 184, 286, 276, 204, 108, 342, 62, 278, 344, 206, 110, 60, 182, 284, 68, 64, 350, 116, 112, 346, 208, 280, 72, 186, 288, 354, 90, 92, 356, 290, 74, 188, 200, 338, 272, 86, 104, 292, 358, 190, 94, 76, 300, 264, 36, 162, 18, 80, 194, 98, 332, 296, 240, 306, 42, 24, 168, 274, 202, 340, 106, 88, 40, 166, 268, 22, 304, 102, 198, 336, 84, 270, 294, 96, 78, 192, 360, 120, 237, 219, 225, 213, 231, 100, 334, 298, 196, 115, 181, 82, 349, 67, 283, 330, 140, 134, 128, 122, 146, 174, 48, 312, 30, 246, 164, 20, 215, 266, 38, 302]
                
                if subunitIDList.contains(subunitID) {
                    renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                               indexCount: indexBufferRegion.length,
                                                               indexType: .uint32,
                                                               indexBuffer: impostorIndexBuffer,
                                                               indexBufferOffset: indexBufferRegion.offset * MemoryLayout<UInt32>.stride)
                }
                subunitID += 1
            }
        }
    }
}
