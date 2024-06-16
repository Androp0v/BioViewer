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
    
    func impostorRenderPass(
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
        Self.impostorRenderPassDescriptor.colorAttachments[0].texture = drawableTexture
        // Clear the drawable texture using the scene's background color
        Self.impostorRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
        
        if AppState.hasDepthPrePasses() {
            // Attach textures. colorAttachments[1] is the depth pre-pass GBuffer texture
            Self.impostorRenderPassDescriptor.colorAttachments[1].texture = depthPrePassTexture
            // Clear the depth texture using the equivalent to 1.0 (max depth)
            Self.impostorRenderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor(
                red: 1.0,
                green: 1.0,
                blue: 1.0,
                alpha: 1.0
            )
        }
                
        // Attach depth texture.
        Self.impostorRenderPassDescriptor.depthAttachment.texture = depthTexture
        // Clear the depth texture (depth is in normalized device coordinates, where 1.0 is the maximum/deepest value).
        Self.impostorRenderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create render command encoder
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: Self.impostorRenderPassDescriptor) else {
            BioViewerLogger.shared.log(
                type: .error,
                category: .proteinRenderer,
                message: "Failed to render impostors: unable to make render command encoder."
            )
            return
        }
        renderCommandEncoder.label = "Depth Pre-pass & Billboard Shading"
        
        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)
        
        // MARK: - Depth pre-pass stage
        
        if AppState.hasDepthPrePasses() {
            self.encodeDepthBoundStage(
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
            BioViewerLogger.shared.log(
                type: .error,
                category: .proteinRenderer,
                message: "Failed to render impostors: MTLPipelineState nil."
            )
            renderCommandEncoder.endEncoding()
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
            BioViewerLogger.shared.log(
                type: .error,
                category: .proteinRenderer,
                message: "Failed to render impostors: ConfigurationSelector nil."
            )
            renderCommandEncoder.endEncoding()
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
                BioViewerLogger.shared.log(
                    type: .error,
                    category: .proteinRenderer,
                    message: "Failed to render impostors: Bond's vertex buffer nil."
                )
                renderCommandEncoder.endEncoding()
                return
            }
            guard let impostorBondIndexBuffer = self.impostorBondIndexBuffer else {
                BioViewerLogger.shared.log(
                    type: .error,
                    category: .proteinRenderer,
                    message: "Failed to render impostors: Bond's index buffer nil."
                )
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
                BioViewerLogger.shared.log(
                    type: .error,
                    category: .proteinRenderer,
                    message: "Failed to render impostors: Bond's MTLPipelineState nil."
                )
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
                BioViewerLogger.shared.log(
                    type: .error,
                    category: .proteinRenderer,
                    message: "Failed to render impostors: Scene's ConfigurationSelector nil."
                )
                renderCommandEncoder.endEncoding()
                return
            }
            guard let indexBufferRegion = configurationSelector.getBondsIndexBufferRegion() else {
                BioViewerLogger.shared.log(
                    type: .error,
                    category: .proteinRenderer,
                    message: "Failed to render impostors: Index's BufferRegion nil."
                )
                renderCommandEncoder.endEncoding()
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
