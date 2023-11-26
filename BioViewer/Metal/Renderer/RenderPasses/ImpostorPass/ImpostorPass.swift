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

extension MutableState {
    
    func impostorRenderPass(
        renderer: ProteinRenderer,
        commandBuffer: MTLCommandBuffer,
        uniformBuffer: inout MTLBuffer,
        drawableTexture: MTLTexture,
        depthTexture: MTLTexture?,
        depthPrePassTexture: MTLTexture?,
        shadowTextures: ShadowTextures,
        variant: ImpostorRenderPassVariant,
        renderBonds: Bool
    ) {
        
        // Ensure transparent buffers are loaded
        guard let billboardVertexBuffers = self.billboardVertexBuffers else { return }
        guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
        
        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        renderer.impostorRenderPassDescriptor.colorAttachments[0].texture = drawableTexture
        // Clear the drawable texture using the scene's background color
        renderer.impostorRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
        
        if AppState.hasDepthPrePasses() {
            // Attach textures. colorAttachments[1] is the depth pre-pass GBuffer texture
            renderer.impostorRenderPassDescriptor.colorAttachments[1].texture = depthPrePassTexture
            // Clear the depth texture using the equivalent to 1.0 (max depth)
            renderer.impostorRenderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor(
                red: 1.0,
                green: 1.0,
                blue: 1.0,
                alpha: 1.0
            )
        }
                
        // Attach depth texture.
        renderer.impostorRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        renderer.impostorRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderer.impostorRenderPassDescriptor) else {
            return
        }
        renderCommandEncoder.label = "Depth Pre-pass & Billboard Shading"
        
        // Set depth state
        renderCommandEncoder.setDepthStencilState(renderer.depthState)
        
        // MARK: - Depth pre-pass stage
        
        if AppState.hasDepthPrePasses() {
            self.encodeDepthBoundStage(
                renderer: renderer,
                renderCommandEncoder: renderCommandEncoder,
                uniformBuffer: &uniformBuffer
            )
        } else {
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

        // Add other buffers to pipeline
        renderCommandEncoder.setVertexBuffer(
            billboardVertexBuffers.billboardMappingBuffer,
            offset: 0,
            index: 2
        )
        renderCommandEncoder.setVertexBuffer(
            billboardVertexBuffers.atomRadiusBuffer,
            offset: 0,
            index: 3
        )
        
        renderCommandEncoder.setVertexBuffer(
            atomColorBuffer,
            offset: 0,
            index: 4
        )
        
        renderCommandEncoder.setFragmentBuffer(
            uniformBuffer,
            offset: 0,
            index: 1
        )
        renderCommandEncoder.setFragmentTexture(
            shadowTextures.shadowDepthTexture,
            index: 1
        )
        renderCommandEncoder.setFragmentSamplerState(
            shadowTextures.shadowSampler,
            index: 0
        )

        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        guard let configurationSelector = scene.configurationSelector else {
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
            renderCommandEncoder.setVertexBuffer(
                impostorBondVertexBuffer,
                offset: 0,
                index: 0
            )
            renderCommandEncoder.setVertexBuffer(
                uniformBuffer,
                offset: 0,
                index: 1
            )
            
            renderCommandEncoder.setFragmentBuffer(
                uniformBuffer,
                offset: 0,
                index: 1
            )

            // Don't render back-facing triangles (cull them)
            renderCommandEncoder.setCullMode(.none)
            
            // Draw primitives
            guard let configurationSelector = scene.configurationSelector else {
                return
            }
            guard let indexBufferRegion = configurationSelector.getBondsIndexBufferRegion() else {
                return
            }
            
            renderCommandEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexBufferRegion.length,
                indexType: .uint32,
                indexBuffer: impostorBondIndexBuffer,
                indexBufferOffset: indexBufferRegion.offset * MemoryLayout<UInt32>.stride
            )
        }
                
        // MARK: - End encoding
        renderCommandEncoder.endEncoding()
    }
}
