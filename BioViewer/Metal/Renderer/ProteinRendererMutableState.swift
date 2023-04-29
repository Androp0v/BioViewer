//
//  ProteinRendererMutableState.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/4/23.
//

import Foundation
import MetalKit
import SwiftUI

extension ProteinRenderer {
    
    actor MutableState {
        
        /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
        var scene = MetalScene()
        /// The `MTLDevice` in charge of rendering the scene.
        let device: MTLDevice
                
        // MARK: - Scheduling
        
        /// Used to index the dynamic buffers.
        var currentFrameIndex: Int
        
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
        /// Benchmark textures.
        var benchmarkTextures = BenchmarkTextures()
        
        // MARK: - Init
        
        init(device: MTLDevice, maxBuffersInFlight: Int, isBenchmark: Bool) {
            
            self.device = device
            
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
        
        func createAtomColorBuffer(
            proteins: [Protein],
            colorList: [Color]?,
            colorBy: ProteinColorByOption?
        ) {
            
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
        
        /// Sets the necessary buffers to display a protein in the renderer using billboarding
        func setColorBuffer(colorBuffer: inout MTLBuffer) {
            self.atomColorBuffer = colorBuffer
        }
        
        /// Sets the necessary buffers to display atom bonds in the renderer using billboarding
        func setBillboardingBonds(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
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
            
            // Create texture for depth-bound shadow render pass pre-pass
            if AppState.hasDepthPrePasses() {
                depthPrePassTextures.makeShadowTextures(
                    device: device,
                    shadowTextureWidth: ShadowTextures.defaultTextureWidth,
                    shadowTextureHeight: ShadowTextures.defaultTextureHeight
                )
            }
        }
        
        func updateMutableStateForNewViewSize(_ size: CGSize, metalLayer: CAMetalLayer?, displayScale: CGFloat?, renderer: ProteinRenderer) {

            // Update render target
            if let metalLayer {
                renderTarget.metalLayer = metalLayer
            }
            if let displayScale {
                renderTarget.displayScale = displayScale
            }
            renderTarget.updateRenderTarget(for: size, renderer: renderer)
            
            // Update scene
            scene.camera.updateProjection(drawableSize: size)
            scene.aspectRatio = Float(size.width / size.height)
            scene.renderResolution = simd_float2(
                Float(renderTarget.renderSize.width),
                Float(renderTarget.renderSize.height)
            )
            
            // Update non-render target textures
            if AppState.hasDepthPrePasses() {
                depthPrePassTextures.makeTextures(
                    device: device,
                    textureWidth: renderTarget.renderSize.width,
                    textureHeight: renderTarget.renderSize.height
                )
            }
        }
        
        func refreshTexturesForNewSettings(renderer: ProteinRenderer) {
            updateMutableStateForNewViewSize(
                CGSize(width: renderTarget.windowSize.width, height: renderTarget.windowSize.height),
                metalLayer: nil,
                displayScale: nil,
                renderer: renderer
            )
        }
        
        func updateMetalFXUpscalingMode(to mode: MetalFXUpscalingMode, renderer: ProteinRenderer) {
            renderTarget.metalFXUpscalingMode = mode
            refreshTexturesForNewSettings(renderer: renderer)
            // Update the mode as seen by the scene
            scene.metalFXUpscalingMode = mode
        }
        
        func updateProteinRenderFactors(ssaa: Float, metalFXUpscaling: Float, renderer: ProteinRenderer) {
            renderTarget.superSamplingCount = ssaa
            renderTarget.metalFXUpscalingFactor = metalFXUpscaling
            refreshTexturesForNewSettings(renderer: renderer)
        }
        
        // MARK: - Scene functions
        
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
    }
}
