//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
import MetalKit
import SwiftUI

class ProteinRenderer: NSObject {
    
    // MARK: - Constants
    
    let maxBuffersInFlight = 3
    
    // MARK: - Scheduling
    
    /// Actor used to protect mutable state that cannot be modified during draws.
    let mutableStateActor: MutableState
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
    
    /// Pipeline state for filling the color buffer (common options: element).
    var simpleFillColorComputePipelineState: MTLComputePipelineState?
    /// Pipeline state for filling the color buffer (extra options: residue, secondary structure...).
    var fillColorComputePipelineState: MTLComputePipelineState?
    
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
        
    // MARK: - Textures
    
    var benchmarkTextures = BenchmarkTextures()
    var shadowTextures = ShadowTextures()
    var depthPrePassTextures = DepthPrePassTextures()

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

    @MainActor
    init(device: MTLDevice, isBenchmark: Bool) {

        self.device = device
        
        self.mutableStateActor = MutableState(
            device: device,
            maxBuffersInFlight: maxBuffersInFlight,
            frameData: scene.frameData
        )
        self.frameBoundarySemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        
        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Benchmark code
        self.isBenchmark = isBenchmark
        
        // Call super initializer
        super.init()
        
        // Create compute pipeline states
        makeSimpleFillColorComputePipelineState(device: device)
        makeFillColorComputePipelineState(device: device)
        
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
        
        // Benchmark textures
        if isBenchmark {
            benchmarkTextures.makeTextures(device: device)
            depthPrePassTextures.makeTextures(
                device: device,
                textureWidth: BenchmarkTextures.benchmarkResolution,
                textureHeight: BenchmarkTextures.benchmarkResolution
            )
            benchmarkTimes = [CFTimeInterval](repeating: .zero, count: BioBenchConfig.numberOfFrames)
        }
        
        // Create shadow textures and sampler
        shadowTextures.makeTextures(
            device: device,
            textureWidth: ShadowTextures.defaultTextureWidth,
            textureHeight: ShadowTextures.defaultTextureHeight
        )
        shadowTextures.makeShadowSampler(device: device)
        
        // Create texture for depth-bound shadow render pass pre-pass
        if AppState.hasDepthPrePasses() {
            depthPrePassTextures.makeShadowTextures(
                device: device,
                shadowTextureWidth: ShadowTextures.defaultTextureWidth,
                shadowTextureHeight: ShadowTextures.defaultTextureHeight
            )
        }
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }

    // MARK: - Public functions
    
    func createAtomColorBuffer(
        proteins: [Protein],
        colorList: [Color]?,
        colorBy: ProteinColorByOption?
    ) async {
        await self.mutableStateActor.createAtomColorBuffer(
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
        await self.mutableStateActor.addOpaqueBuffers(
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
        await self.mutableStateActor.setBillboardingBuffers(
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
        await self.mutableStateActor.setColorBuffer(colorBuffer: &colorBuffer)
    }
    
    /// Sets the necessary buffers to display atom bonds in the renderer using billboarding
    func setBillboardingBonds(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) async {
        await self.mutableStateActor.setBillboardingBonds(
            vertexBuffer: &vertexBuffer,
            indexBuffer: &indexBuffer,
            scene: scene
        )
    }
    
    #if DEBUG
    func setDebugPointsBuffer(vertexBuffer: inout MTLBuffer) async {
        await self.mutableStateActor.setDebugPointsBuffer(
            vertexBuffer: &vertexBuffer,
            scene: self.scene
        )
    }
    #endif
    
    /// Deallocates the MTLBuffers used to render a protein
    func removeBuffers() async {
        await self.mutableStateActor.removeBuffers(scene: self.scene)
    }

    /// Make new impostor pipeline variant.
    func remakeImpostorPipelineForVariant(variant: ImpostorRenderPassVariant) {
        makeImpostorRenderPipelineState(device: self.device, variant: variant)
    }
}

// MARK: - Drawing
extension ProteinRenderer: MTKViewDelegate {

    /// This will be called when the ProteinMetalView changes size
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TO-DO: Update G-Buffer texture size to match view size
        self.scene.camera.updateProjection(drawableSize: size)
        self.scene.aspectRatio = Float(size.width / size.height)
        
        self.viewResolution = size
        
        if AppState.hasDepthPrePasses() {
            depthPrePassTextures.makeTextures(
                device: device,
                textureWidth: Int(size.width),
                textureHeight: Int(size.height)
            )
        }
        
        // TO-DO: Enqueue draw calls so this doesn't drop the FPS
        view.draw()
    }

    // This is called periodically to render the scene contents on display
    func draw(in view: MTKView) {
        Task {
            await mutableStateActor.drawFrame(from: self, in: view)
        }
    }

}
