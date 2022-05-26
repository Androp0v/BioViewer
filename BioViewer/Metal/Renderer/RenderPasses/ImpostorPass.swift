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
    
    func impostorRenderPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer, drawableTexture: MTLTexture, depthTexture: MTLTexture?, depthBoundTexture: MTLTexture?, shadowTextures: ShadowTextures, variant: ImpostorRenderPassVariant, renderBonds: Bool) {
        
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
        
        // MARK: - Impostor sphere rendering
        // Set pipeline state for the variant
        var variantPipelineState: MTLRenderPipelineState?
        switch variant {
        case .solidSpheres, .ballAndSticks:
            variantPipelineState = impostorRenderingPipelineState
        case .solidSpheresHQ, .ballAndSticksHQ:
            variantPipelineState = impostorHQRenderingPipelineState
        }
        guard let impostorRenderingPipelineState = variantPipelineState else {
            return
        }
        renderCommandEncoder.setRenderPipelineState(impostorRenderingPipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(impostorVertexBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(atomColorBuffer,
                                             offset: 0,
                                             index: 2)
        renderCommandEncoder.setVertexBuffer(disabledAtomsBuffer,
                                             offset: 0,
                                             index: 3)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 4)
        
        renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                               offset: 0,
                                               index: 1)
        renderCommandEncoder.setFragmentTexture(depthBoundTexture,
                                                index: 0)
        renderCommandEncoder.setFragmentTexture(shadowTextures.shadowDepthTexture,
                                                index: 1)
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
        
        // MARK: - Bond rendering
        if renderBonds {
            guard let impostorBondVertexBuffer = self.impostorBondVertexBuffer else {
                renderCommandEncoder.endEncoding()
                return
            }
            guard let impostorBondIndexBuffer = self.impostorBondIndexBuffer else {
                renderCommandEncoder.endEncoding()
                return
            }
            
            // Set pipeline state for the variant
            var bondVariantPipelineState: MTLRenderPipelineState?
            switch variant {
            case .solidSpheres, .ballAndSticks:
                bondVariantPipelineState = impostorBondRenderingPipelineState
            case .solidSpheresHQ, .ballAndSticksHQ:
                // TO-DO: HQ impostorHQBondRenderingPipelineStage
                bondVariantPipelineState = impostorBondRenderingPipelineState
            }
            guard let impostorBondRenderingPipelineState = bondVariantPipelineState else {
                renderCommandEncoder.endEncoding()
                return
            }
            renderCommandEncoder.setRenderPipelineState(impostorBondRenderingPipelineState)
            
            // Add buffers to pipeline
            renderCommandEncoder.setVertexBuffer(impostorBondVertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                                 offset: 0,
                                                 index: 1)
            
            renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                                   offset: 0,
                                                   index: 1)

            // Don't render back-facing triangles (cull them)
            renderCommandEncoder.setCullMode(.back)
            
            // Draw primitives
            guard let indexBufferLength = scene.configurationSelector?.getBondsIndexBufferRegion()?.length else {
                renderCommandEncoder.endEncoding()
                return
            }
            guard let indexBufferOffset = scene.configurationSelector?.getBondsIndexBufferRegion()?.offset else {
                renderCommandEncoder.endEncoding()
                return
            }
            renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                       indexCount: indexBufferLength,
                                                       indexType: .uint32,
                                                       indexBuffer: impostorBondIndexBuffer,
                                                       indexBufferOffset: indexBufferOffset * MemoryLayout<UInt32>.stride)
        }
        
        // MARK: - End encoding
        renderCommandEncoder.endEncoding()
    }
}
