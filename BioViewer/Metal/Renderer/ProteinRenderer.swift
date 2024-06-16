//
//  ProteinRendererMutableState.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/4/23.
//

import BioViewerFoundation
import Foundation
import MetalKit
#if canImport(MetalFX)
import MetalFX
#endif
import SwiftUI

/// Object handling protein rendering. This includes textures, buffers, and other data structures.
actor ProteinRenderer {
    
    /// The `MTLDevice` in charge of rendering the scene.
    let device: MTLDevice
    /// Command queue.
    let commandQueue: MTLCommandQueue?
    /// The default library.
    let library: MTLLibrary?
    
    /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
    private(set) var scene = MetalScene()
    /// Resolution of the view
    var viewResolution: CGSize?
            
    // MARK: - Scheduling
    
    let maxBuffersInFlight = 3
    /// Used to signal that a new frame is ready to be computed by the CPU.
    var frameBoundarySemaphore: DispatchSemaphore
    /// Used to index the dynamic buffers.
    var currentFrameIndex: Int
    /// Frame GPU execution time, exponentially averaged.
    var lastFrameGPUTime = CFTimeInterval()
    
    // MARK: - Benchmark
    
    /// Whether the current `ProteinRenderer` is part of a benchmark.
    let isBenchmark: Bool
    /// The GPU execution times for the las N frames in benchmark mode.
    /// Property is `nil` when not in benchmark mode.
    var benchmarkTimes: [CFTimeInterval]?
    /// Number of benchmarked frames.
    var benchmarkedFrames: Int = 0
    
    // MARK: - Buffers
    
    /// Used to pass the geometry vertex data to the shader when using a dense mesh
    var opaqueVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader when using a dense mesh
    var opaqueIndexBuffer: MTLBuffer?
    
    /// Used to pass the geometry vertex data to the shader when using billboarding
    var billboardVertexBuffers: BillboardVertexBuffers?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader  when using billboarding
    var impostorIndexBuffer: MTLBuffer?
    
    #if DEBUG
    /// Used to debug things displaying points
    var debugPointVertexBuffer: MTLBuffer?
    #endif
    
    /// Used to pass the atomic element data to the shader (used for coloring, size...).
    var atomElementBuffer: MTLBuffer?
    /// Used to pass the subunit index to the shader (used for coloring).
    var atomSubunitBuffer: MTLBuffer?
    /// Used to pass the residue data for each atom to the shader (used for coloring, size...).
    var atomResidueBuffer: MTLBuffer?
    /// Used to pass the secondary structure data for each atom to the shader (used for coloring, size...).
    var atomSecondaryStructureBuffer: MTLBuffer?
    
    /// Used to pass the atom base color to the shader (used for coloring, size...).
    var atomColorBuffer: MTLBuffer?
    /// Used to pass constant frame data to the shader.
    var uniformBuffers: [MTLBuffer]?
    
    /// Used to pass the geometry vertex data to the shader when using billboarding bonds
    var impostorBondVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader  when using billboarding bonds.
    var impostorBondIndexBuffer: MTLBuffer?
    
    // MARK: - Textures
    
    var renderTarget = ProteinRenderTarget()
    
    /// Depth texture used in the depth pre-pass.
    var depthPrePassTextures = DepthPrePassTextures()
    /// Shadow textures.
    var shadowTextures = ShadowTextures()
    /// Ambient occlusion texture.
    var ambientOcclusionTexture = AmbientOcclusion3DTexture()
    /// Benchmark textures.
    var benchmarkTextures = BenchmarkTextures()
    
    // MARK: - Depth Texture descriptors
    
    static let shadowDepthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()

    static let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()
    
    // MARK: - Render pass descriptors
    
    static let shadowRenderPassDescriptor: MTLRenderPassDescriptor = {
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
    
    static let impostorRenderPassDescriptor: MTLRenderPassDescriptor = {
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
    
    static let debugPointsRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .load
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.loadAction = .load
        descriptor.depthAttachment.storeAction = .dontCare
        return descriptor
    }()
    
    // MARK: -  PipelineStateBundle bundles
    
    let createSphereModelBundle = PipelineStateBundle()
    let createBondsBundle = PipelineStateBundle()
    let createSASPointsBundle = PipelineStateBundle()
    let removeSASPointsInsideSolidBundle = PipelineStateBundle()
    
    // MARK: - Render Pipeline Statues
    
    /// Shadow depth state.
    var shadowDepthState: MTLDepthStencilState?
    /// Depth state.
    var depthState: MTLDepthStencilState?
    
    // MARK: - Compute Pipeline States
    
    /// Pipeline state for filling the color buffer (element, subunit, residue, secondary structure...).
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
    
    // MARK: - Upscaling
    
    #if canImport(MetalFX)
    /// Metal FX Upscaler based solely on spatial data.
    var metalFXSpatialScaler: MTLFXSpatialScaler?
    /// Metal FX Upscaler based on spatial and temporal data.
    var metalFXTemporalScaler: MTLFXTemporalScaler?
    #endif
    
    // MARK: - Init
    
    init(isBenchmark: Bool) {
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.device = device
        
        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        self.frameBoundarySemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        self.library = device.makeDefaultLibrary()
        
        self.isBenchmark = isBenchmark
        
        // Initialize the uniforms triple buffering array
        self.uniformBuffers = [MTLBuffer]()
        
        // Add buffers to uniforms buffer array
        for _ in 0..<maxBuffersInFlight {
            var inoutFrameData = scene.currentFrameData
            let uniformBuffer = device.makeBuffer(
                bytes: &inoutFrameData,
                length: MemoryLayout<FrameData>.stride,
                options: []
            )
            guard let uniformBuffer = uniformBuffer else {
                NSLog("Unable to create uniform buffer.")
                continue
            }
            uniformBuffers?.append(uniformBuffer)
        }
        
        // Property initialization
        self.currentFrameIndex = 0
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: Self.depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: Self.depthDescriptor)
        
        if isBenchmark {
            // Setup benchmark times
            benchmarkTimes = [CFTimeInterval](repeating: .zero, count: BioBenchConfig.numberOfFrames)
        }
        
        // Create Metal pipeline states
        Task {
            await createPipelineStates()
            await createTextures(isBenchmark: isBenchmark)
        }
    }
    
    // MARK: - Functions
    
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
    
    // MARK: - Buffer functions
        
    /// Creates a new buffer to hold the color of each atom, if the existing color buffer does not have the appropriate size.
    func createAtomColorBufferIfNeeded(
        proteins: [Protein],
        colorBy: ProteinColorByOption?
    ) {
        // Check whether a buffer of the required size already exists.
        let currentBufferLength = atomColorBuffer?.length ?? 0
        let newBufferLength = proteins.reduce(0) { $0 + $1.atomCount } * MemoryLayout<SIMD4<Int16>>.stride
        guard newBufferLength != currentBufferLength else {
            // The existing buffer can be reused.
            return
        }
        
        // Get the number of configurations
        var atomAndConfigurationCount = 0
        for protein in proteins {
            atomAndConfigurationCount += protein.atomCount * protein.configurationCount
        }
        
        // WORKAROUND: The memory layout should conform to simd_half3's stride, which is
        // syntactic sugar for SIMD3<Float16>, but Float16 is (still) unavailable on macOS
        // due to lack of support on x86. We assume SIMD3<Int16> is packed in the same way
        // Metal packs the half3 type.
        guard let generatedColorBuffer = device.makeBuffer(
            length: atomAndConfigurationCount * MemoryLayout<SIMD3<Int16>>.stride
        ) else { return }
        
        self.atomColorBuffer = generatedColorBuffer
    }
    
    /// Adds the necessary buffers to display a protein in the renderer with a dense mesh
    func addOpaqueBuffers(
        vertexBuffer: inout MTLBuffer,
        atomTypeBuffer: inout MTLBuffer,
        indexBuffer: inout MTLBuffer
    ) {
        self.opaqueVertexBuffer = vertexBuffer
        self.atomElementBuffer = atomTypeBuffer
        self.opaqueIndexBuffer = indexBuffer
        scene.needsRedraw = true
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
    ) {
        self.billboardVertexBuffers = billboardVertexBuffers
        self.atomElementBuffer = atomElementBuffer
        self.atomSubunitBuffer = subunitBuffer
        self.atomResidueBuffer = atomResidueBuffer
        self.atomSecondaryStructureBuffer = atomSecondaryStructureBuffer
        self.impostorIndexBuffer = indexBuffer
        scene.needsRedraw = true
        scene.lastColorPassRequest = CACurrentMediaTime()
        scene.configurationSelector = configurationSelector
        scene.currentFrameData.atoms_per_configuration = Int32(configurationSelector.atomsPerConfiguration)
    }
    
    /// Sets the necessary buffers to display atom bonds in the renderer using billboarding
    func setBillboardingBonds(vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer) {
        self.impostorBondVertexBuffer = vertexBuffer
        self.impostorBondIndexBuffer = indexBuffer
        scene.needsRedraw = true
    }
    
    #if DEBUG
    func setDebugPointsBuffer(vertexBuffer: inout MTLBuffer) {
        self.debugPointVertexBuffer = vertexBuffer
        scene.needsRedraw = true
    }
    #endif
    
    func populateImpostorSphereBuffers(proteins: [Protein], configuration: VisualizationConfiguration) async {
        
        // Generate a billboard quad for each atom in the protein
        guard let generatedImpostorData = await createImpostorSpheres(
            proteins: proteins,
            atomRadii: configuration.atomRadii
        ) else { return }
        
        // Create ConfigurationSelector for new data
        guard let configurationSelector = createConfigurationSelector(proteins: proteins) else { return }
        
        // Pass the new mesh to the renderer
        setBillboardingBuffers(
            billboardVertexBuffers: generatedImpostorData.vertexBuffer,
            atomElementBuffer: generatedImpostorData.atomElementBuffer,
            subunitBuffer: generatedImpostorData.subunitBuffer,
            atomResidueBuffer: generatedImpostorData.atomResidueBuffer,
            atomSecondaryStructureBuffer: generatedImpostorData.atomSecondaryStructureBuffer,
            indexBuffer: generatedImpostorData.indexBuffer,
            configurationSelector: configurationSelector
        )
        
        // Create color buffer if needed
        createAtomColorBufferIfNeeded(
            proteins: proteins,
            colorBy: configuration.colorBy
        )
    }
    
    func populateBondBuffers(bondData: [BondStruct]) async {
        // Create bond buffers for the structure
        guard let bondBuffers = await createBondsGeometry(bondData: bondData) else {
            return
        }
        
        // Set the buffers
        setBillboardingBonds(
            vertexBuffer: bondBuffers.vertexBuffer,
            indexBuffer: bondBuffers.indexBuffer
        )
    }
    
    /// Deallocates the MTLBuffers used to render a protein
    func removeBuffers() {
        self.opaqueVertexBuffer = nil
        self.atomElementBuffer = nil
        self.opaqueIndexBuffer = nil
        scene.needsRedraw = true
    }
    
    // MARK: - Texture functions
    
    func createTextures(isBenchmark: Bool) {
        // Benchmark textures
        if isBenchmark {
            benchmarkTextures.makeTextures(device: device)
            depthPrePassTextures.makeTextures(
                device: device,
                textureWidth: BenchmarkTextures.benchmarkResolution,
                textureHeight: BenchmarkTextures.benchmarkResolution
            )
        }
        
        // Create shadow textures and sampler
        shadowTextures.makeTextures(
            device: device,
            textureWidth: ShadowTextures.defaultTextureWidth,
            textureHeight: ShadowTextures.defaultTextureHeight
        )
        shadowTextures.makeShadowSampler(device: device)
        
        // Create ambient occlusion texture
        ambientOcclusionTexture.makeTexture(device: device)
        
        // Create texture for depth-bound shadow render pass pre-pass
        if AppState.hasDepthPrePasses() {
            depthPrePassTextures.makeShadowTextures(
                device: device,
                shadowTextureWidth: ShadowTextures.defaultTextureWidth,
                shadowTextureHeight: ShadowTextures.defaultTextureHeight
            )
        }
    }
    
    func updateMutableStateForNewViewSize(_ size: CGSize, metalLayer: CAMetalLayer?, displayScale: CGFloat?) {
        
        self.viewResolution = size

        // Update render target.
        if let metalLayer {
            renderTarget.metalLayer = metalLayer
        }
        if let displayScale {
            renderTarget.displayScale = displayScale
        }
        renderTarget.updateRenderTarget(for: size, device: device)
        
        // Update scene
        scene.camera.updateProjection(drawableSize: size)
        scene.aspectRatio = Float(size.width / size.height)
        scene.renderResolution = simd_float2(
            Float(renderTarget.renderSize.width),
            Float(renderTarget.renderSize.height)
        )
        
        // Remake MetalFX upscalers (if needed).
        switch renderTarget.metalFXUpscalingMode {
        case .temporal:
            makeTemporalScaler(
                inputSize: MTLSizeMake(
                    renderTarget.renderSize.width,
                    renderTarget.renderSize.height,
                    1
                ),
                outputSize: MTLSizeMake(
                    renderTarget.upscaledSize.width,
                    renderTarget.upscaledSize.height,
                    1
                )
            )
        case .spatial:
            makeSpatialScaler(
                inputSize: MTLSizeMake(
                    renderTarget.renderSize.width,
                    renderTarget.renderSize.height,
                    1
                ),
                outputSize: MTLSizeMake(
                    renderTarget.upscaledSize.width,
                    renderTarget.upscaledSize.height,
                    1
                )
            )
        case .none:
            break
        }
        
        // Update non-render target textures.
        if AppState.hasDepthPrePasses() {
            depthPrePassTextures.makeTextures(
                device: device,
                textureWidth: renderTarget.renderSize.width,
                textureHeight: renderTarget.renderSize.height
            )
        }
    }
    
    func refreshTexturesForNewSettings() {
        updateMutableStateForNewViewSize(
            CGSize(width: renderTarget.windowSize.width, height: renderTarget.windowSize.height),
            metalLayer: nil,
            displayScale: nil
        )
    }
    
    func updateMetalFXUpscalingMode(to mode: MetalFXUpscalingMode, renderer: ProteinRenderer) {
        renderTarget.metalFXUpscalingMode = mode
        refreshTexturesForNewSettings()
        // Update the mode as seen by the scene
        scene.metalFXUpscalingMode = mode
    }
    
    func updateProteinRenderFactors(ssaa: Float, metalFXUpscaling: Float) {
        renderTarget.superSamplingCount = ssaa
        renderTarget.metalFXUpscalingFactor = metalFXUpscaling
        refreshTexturesForNewSettings()
    }
    
    // MARK: - Pipeline functions
    
    /// Make new impostor pipeline variant.
    func remakeImpostorPipelineForVariant(variant: ImpostorRenderPassVariant) {
        makeImpostorRenderPipelineState(device: self.device, variant: variant)
    }
    
    private func createPipelineStates() {
        // Create compute pipeline states
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
    }
    
    // MARK: - Scene functions
    
    func getAtomRadii() -> AtomRadii {
        return scene.atom_radii
    }
    
    func setAtomRadii(_ newRadii: AtomRadii) {
        scene.atom_radii = newRadii
    }
    
    func setAutorotating(to autorotating: Bool) {
        scene.autorotating = autorotating
    }
    
    func setSunDirection(theta: Angle, phi: Angle) {
        scene.setSunDirection(theta: theta, phi: phi)
    }
    
    func setHasShadows(_ hasShadows: Bool) {
        scene.hasShadows = hasShadows
    }
    
    func setShadowStrength(_ strength: Float) {
        scene.shadowStrength = strength
    }
    
    func setHasDepthCueing(_ hasDepthCueing: Bool) {
        scene.hasDepthCueing = hasDepthCueing
    }
    
    func setDepthCueingStrength(_ strength: Float) {
        scene.depthCueingStrength = strength
    }
    
    func setCameraFocalLength(_ focalLength: Float) {
        scene.camera.updateFocalLength(
            focalLength: focalLength,
            aspectRatio: scene.aspectRatio
        )
    }
    
    func setBackgroundColor(_ color: CGColor) {
        scene.backgroundColor = color
    }
    
    func setColorFill(_ colorFill: FillColorInput) {
        scene.colorFill = colorFill
    }
    
    func animateColorFillChange(to colorFill: FillColorInput) {
        scene.animator?.animatedFillColorChange(
            initialColors: scene.colorFill,
            finalColors: colorFill,
            duration: 0.15
        )
    }
    
    func setBondColor(_ color: CGColor) {
        scene.bondColor = color
    }
    
    func previousConfiguration() {
        scene.configurationSelector?.previousConfiguration()
        scene.needsRedraw = true
    }
    
    func nextConfiguration() {
        scene.configurationSelector?.nextConfiguration()
        scene.needsRedraw = true
    }
    
    func setIsPlaying(_ isPlaying: Bool) {
        scene.isPlaying = isPlaying
    }
    
    func setAutorotating(_ autorotating: Bool) {
        scene.autorotating = autorotating
    }
    
    func resetCamera() {
        scene.resetCamera()
    }
    
    func getUserRotationQuaternion() -> simd_quatd {
        return scene.userRotationQuaternion
    }
    
    func setUserRotationQuaternion(_ quaternion: simd_quatd) {
        scene.userRotationQuaternion = quaternion
    }
    
    func getModelTranslationMatrix() -> simd_float4x4 {
        return scene.modelTranslationMatrix
    }
    
    func getCamera() -> Camera {
        return scene.camera
    }
    
    func getCameraPosition() -> simd_float3 {
        return scene.cameraPosition
    }
    
    func translateCameraXY(x: Float, y: Float) {
        scene.translateCamera(
            x: x,
            y: y
        )
    }
    
    func setCameraDistanceToModel(_ newDistance: Float) {
        scene.updateCameraDistanceToModel(
            distanceToModel: newDistance,
            newBoundingVolume: nil
        )
    }
    
    func fitCameraToBoundingVolume(_ boundingVolume: BoundingVolume) {
        let cameraDistanceToFit = scene.camera.distanceToFitInFrustum(
            sphereRadius: boundingVolume.sphere.radius,
            aspectRatio: scene.aspectRatio
        )
        scene.updateCameraDistanceToModel(
            distanceToModel: cameraDistanceToFit,
            newBoundingVolume: boundingVolume
        )
    }
    
    func updateBonds(bondData: [BondStruct], bondsPerConfiguration: [Int], bondsConfigurationArrayStart: [Int]) async {
        
        guard let configurationSelector = scene.configurationSelector else {
            return
        }

        // Avoid trying to create a buffer with 0 length if no bonds are found (causes a crash)
        if !bondData.isEmpty {
            await populateBondBuffers(bondData: bondData)
        }

        configurationSelector.addBonds(
            bondsPerConfiguration: bondsPerConfiguration,
            bondArrayStarts: bondsConfigurationArrayStart
        )
    }
    
    func setVisualization(_ visualization: ProteinVisualizationOption) {
        scene.currentVisualization = visualization
    }
    
    func exportBenchmarkTextures() -> CGImage? {
        return benchmarkTextures.colorTexture.getCGImage()
    }
    
    // MARK: - Configuration Selector
    
    func createConfigurationSelector(proteins: [Protein]) -> ConfigurationSelector? {
        
        if let currentSelector = scene.configurationSelector, currentSelector.proteins == proteins {
            return currentSelector
        }

        var totalAtomCount: Int = 0
        var subunitIndices = [Int]()
        var subunitLengths = [Int]()
        for protein in proteins {
            totalAtomCount += protein.atomCount
        }
        return ConfigurationSelector(
            for: proteins,
            atomsPerConfiguration: totalAtomCount,
            configurationCount: proteins.first?.configurationCount ?? 1 // FIXME: Remove ?? 1
        )
    }
    
    // MARK: - Benchmarks
    
    func resetBenchmarkedFrames() {
        self.benchmarkedFrames = 0
    }
}
