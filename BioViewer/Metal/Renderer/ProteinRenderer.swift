//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
@preconcurrency import MetalKit
import MetalFX
import SwiftUI

class ProteinRenderer: NSObject {
    
    // MARK: - Constants
    
    let maxBuffersInFlight = 3
    
    // MARK: - Scheduling
    
    var renderThread: Thread?
    /// Actor used to protect mutable state that cannot be modified during draws.
    let protectedMutableState: MutableState
    /// Used to signal that a new frame is ready to be computed by the CPU.
    var frameBoundarySemaphore: DispatchSemaphore
    /// Frame GPU execution time, exponentially averaged.
    var lastFrameGPUTime = CFTimeInterval()
    
    // MARK: - Benchmark
    
    /// Whether the current `ProteinRenderer` is part of a benchmark.
    var isBenchmark: Bool
    /// The GPU execution times for the las N frames in benchmark mode.
    /// Property is `nil` when not in benchmark mode.
    var benchmarkTimes: [CFTimeInterval]?
    /// Number of benchmarked frames.
    var benchmarkedFrames: Int = 0
    
    // MARK: - Metal variables
    
    /// GPU
    var device: MTLDevice
    /// Command queue.
    var commandQueue: MTLCommandQueue?
    /// Resolution of the view
    var viewResolution: CGSize?
    
    // MARK: - Upscaling
    
    /// Metal FX Upscaler based solely on spatial data.
    var metalFXSpatialScaler: MTLFXSpatialScaler?
    /// Metal FX Upscaler based on spatial and temporal data.
    var metalFXTemporalScaler: MTLFXTemporalScaler?
    
    // MARK: - Compute Pipeline States
    
    /// Pipeline state for filling the color buffer (common options: element).
    var simpleFillColorComputePipelineState: MTLComputePipelineState?
    /// Pipeline state for filling the color buffer (extra options: residue, secondary structure...).
    var fillColorComputePipelineState: MTLComputePipelineState?
    /// Pipeline state for the compute post-processing step of blurring the shadows.
    var shadowBlurPipelineState: MTLComputePipelineState?
    /// Pipeline state for motion texture generation.
    var motionPipelineState: MTLComputePipelineState?
    
    // MARK: - Render Pipeline States
    
    /// Pipeline state for the shadow depth pre-pass.
    var shadowDepthPrePassRenderPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the directional shadow creation.
    var shadowRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the directional shadow creation.
    var shadowHQRenderingPipelineState: MTLRenderPipelineState?
    
    var opaqueRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times).
    
    /// Pipeline state for the depth pre-pass.
    var depthPrePassRenderPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the opaque geometry rendering.
    var impostorRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times) in Photo Mode.
    var impostorHQRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times).
    ///
    var impostorBondRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times) in Photo Mode.
    var impostorBondHQRenderingPipelineState: MTLRenderPipelineState?
    
    #if DEBUG
    /// Pipeline to debug things using points.
    var debugPointsRenderingPipelineState: MTLRenderPipelineState?
    #endif
    
    /// Shadow depth state.
    var shadowDepthState: MTLDepthStencilState?
    /// Depth state.
    var depthState: MTLDepthStencilState?

    // MARK: - Runtime variables
    
    /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
    var scene = MetalScene()
    /// Data source with the proteins that back the rendering.
    var proteinDataSource: ProteinDataSource?
    
    /// If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?
    
    /// Get the MTLClearColor for the scene's background color. Defaults to black if color can't be retrieved.
    func getBackgroundClearColor() -> MTLClearColor {
        
        // Convert color to RGB from other color spaces (i.e. grayscale) as MTLClearColor requires
        // a RGBA value.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let rgbaColor = scene.backgroundColor.converted(to: rgbColorSpace, intent: .defaultIntent, options: nil) else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        // We expect 4 color components in RGBA
        guard rgbaColor.numberOfComponents == 4 else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        guard let rgbaColorComponents = rgbaColor.components else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        return MTLClearColor(
            red: rgbaColorComponents[0],
            green: rgbaColorComponents[1],
            blue: rgbaColorComponents[2],
            alpha: rgbaColorComponents[3]
        )
    }
    
    // MARK: - Render pass descriptors
    
    let shadowRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // Final shadow color texture, unused
        descriptor.colorAttachments[0].loadAction = .dontCare
        descriptor.colorAttachments[0].storeAction = .dontCare
        // Depth-bound pre-pass texture
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .dontCare
        // Final depth texture (Shadow Map)
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        
        return descriptor
    }()
    
    let impostorRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // Final drawable texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        // Depth-bound pre-pass texture
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .dontCare
        // Final depth texture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        
        return descriptor
    }()
    
    let debugPointsRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .load
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.loadAction = .load
        descriptor.depthAttachment.storeAction = .dontCare
        return descriptor
    }()
    
    // MARK: - Texture descriptors
    
    let shadowDepthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()

    let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()
    
    // MARK: - Initialization

    init(device: MTLDevice, isBenchmark: Bool) {

        self.device = device

        self.frameBoundarySemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        
        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Benchmark code
        self.isBenchmark = isBenchmark
                
        // Protected state
        self.protectedMutableState = MutableState(
            device: device,
            maxBuffersInFlight: maxBuffersInFlight,
            frameData: scene.currentFrameData,
            isBenchmark: isBenchmark
        )
        
        if isBenchmark {
            benchmarkTimes = [CFTimeInterval](repeating: .zero, count: BioBenchConfig.numberOfFrames)
        }
        
        // Call super initializer
        super.init()
        
        // Render thread updates
        startRenderThread()
        
        // Create compute pipeline states
        makeSimpleFillColorComputePipelineState(device: device)
        makeFillColorComputePipelineState(device: device)
        makeShadowBlurringComputePipelineState(device: device)
        if device.supportsFamily(.metal3) {
            makeMotionComputePipelineState(device: device)
        }
        
        // Create render pipeline states
        makeShadowRenderPipelineState(device: device, highQuality: false)
        if AppState.hasDepthPrePasses() {
            makeShadowDepthPrePassRenderPipelineState(device: device)
            makeDepthPrePassRenderPipelineState(device: device)
        }
        makeOpaqueRenderPipelineState(device: device)
        makeImpostorRenderPipelineState(device: device, variant: .solidSpheres)
        makeImpostorBondRenderPipelineState(device: device, variant: .solidSpheres)
        #if DEBUG
        makeDebugPointsPipelineState(device: device)
        #endif
        
        Task {
            await protectedMutableState.createTextures(isBenchmark: isBenchmark)
        }
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    // MARK: - Render thread
    func startRenderThread() {
        renderThread = Thread { [weak self] in
            while let self, !(self.renderThread?.isCancelled ?? false) {
                RunLoop.current.run(
                    mode: .default,
                    before: Date.distantFuture
                )
            }
            Thread.exit()
        }
        renderThread?.name = "ProteinRenderer Thread"
        renderThread?.start()
    }

    // MARK: - Public functions
    
    func createAtomColorBuffer(
        proteins: [Protein],
        colorList: [Color]?,
        colorBy: ProteinColorByOption?
    ) async {
        await self.protectedMutableState.createAtomColorBuffer(
            proteins: proteins,
            colorList: colorList,
            colorBy: colorBy
        )
    }
    
    /// Adds the necessary buffers to display a protein in the renderer with a dense mesh
    func addOpaqueBuffers(
        vertexBuffer: inout MTLBuffer,
        atomTypeBuffer: inout MTLBuffer,
        indexBuffer: inout MTLBuffer
    ) async {
        await self.protectedMutableState.addOpaqueBuffers(
            vertexBuffer: &vertexBuffer,
            atomTypeBuffer: &atomTypeBuffer,
            indexBuffer: &indexBuffer,
            scene: self.scene
        )
    }
    
    /// Sets the necessary buffers to display a protein in the renderer using billboarding
    func setBillboardingBuffers(
        billboardVertexBuffers: BillboardVertexBuffers,
        atomElementBuffer: MTLBuffer,
        subunitBuffer: MTLBuffer?,
        atomResidueBuffer: MTLBuffer?,
        atomSecondaryStructureBuffer: MTLBuffer?,
        indexBuffer: MTLBuffer,
        configurationSelector: ConfigurationSelector
    ) async {
        await self.protectedMutableState.setBillboardingBuffers(
            billboardVertexBuffers: billboardVertexBuffers,
            atomElementBuffer: atomElementBuffer,
            subunitBuffer: subunitBuffer,
            atomResidueBuffer: atomResidueBuffer,
            atomSecondaryStructureBuffer: atomSecondaryStructureBuffer,
            indexBuffer: indexBuffer,
            configurationSelector: configurationSelector,
            scene: self.scene
        )
    }
    
    /// Sets the necessary buffers to display a protein in the renderer using billboarding
    func setColorBuffer(colorBuffer: inout MTLBuffer) async {
        await self.protectedMutableState.setColorBuffer(colorBuffer: &colorBuffer)
    }
    
    /// Sets the necessary buffers to display atom bonds in the renderer using billboarding
    func setBillboardingBonds(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) async {
        await self.protectedMutableState.setBillboardingBonds(
            vertexBuffer: &vertexBuffer,
            indexBuffer: &indexBuffer,
            scene: scene
        )
    }
    
    #if DEBUG
    func setDebugPointsBuffer(vertexBuffer: inout MTLBuffer) async {
        await self.protectedMutableState.setDebugPointsBuffer(
            vertexBuffer: &vertexBuffer,
            scene: self.scene
        )
    }
    #endif
    
    /// Deallocates the MTLBuffers used to render a protein
    func removeBuffers() async {
        await self.protectedMutableState.removeBuffers(scene: self.scene)
    }

    /// Make new impostor pipeline variant.
    func remakeImpostorPipelineForVariant(variant: ImpostorRenderPassVariant) {
        makeImpostorRenderPipelineState(device: self.device, variant: variant)
    }
}

// MARK: - Drawing
extension ProteinRenderer {
    
    func drawableSizeChanged(to size: CGSize, layer: CAMetalLayer, displayScale: CGFloat) {
        self.scene.camera.updateProjection(drawableSize: size)
        self.scene.aspectRatio = Float(size.width / size.height)
        self.viewResolution = size
        Task {
            await protectedMutableState.updateTexturesForNewViewSize(
                size,
                metalLayer: layer,
                displayScale: displayScale,
                renderer: self
            )
        }
    }

    // This is called periodically to render the scene contents on display
    func draw(in layer: CAMetalLayer) {
        Task {
            await protectedMutableState.drawFrame(from: self, in: layer)
        }
    }

}
