//
//  MetalScheduler.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

import Foundation
import Metal
import simd

class MetalScheduler {

    // MARK: - Properties

    static let shared = MetalScheduler()

    public enum Task {
        case createSASPoints
        case none
    }

    // MARK: - Private properties

    private let device: MTLDevice!
    private let queue: MTLCommandQueue?
    private let library: MTLLibrary?

    // MTLCompiledFunction bundles
    private var createSASPointsBundle = MTLCompiledFunction()
    private var removeSASPointsInsideSolidBundle = MTLCompiledFunction()

    // DispatchQueue for synchronization
    private var metalDispatchQueue: DispatchQueue

    // MARK: - Initialization

    private init() {
        // Initialize device
        self.device = MTLCreateSystemDefaultDevice()

        // Initialize command queue
        self.queue = device.makeCommandQueue()

        // Initialize default Metal library
        self.library = device.makeDefaultLibrary()

        // Create a queue to dispath metal work (FIFO) to synchronize work
        metalDispatchQueue = DispatchQueue.init(label: "Metal Scheduler", qos: .default)

        // Precompile metal functions and pipeline states
        precompileFunctions()

    }

    // MARK: - Public functions

    public func createSASPoints(protein: Protein, sceneDelegate: ProteinViewSceneDelegate) {

        metalDispatchQueue.sync {

            // Variables
            var probeRadius: Float = 1.4
            let spherePoints: Int = 12

            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: Array(protein.atoms),
                length: protein.atomCount * MemoryLayout<simd_float3>.stride
            )
            let generatedSpherePositions = device.makeBuffer(
                length: protein.atomCount * spherePoints * MemoryLayout<simd_float3>.stride
            )

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Iterate over each atom type
            for atomSection in AtomSectionSequence(protein: protein) {
                
                // Set the apropiate radius and probe radius as function constants
                var atomRadius = getAtomicRadius(atomType: atomSection.atomIdentifier)

                guard atomSection.length != 0 else { continue }

                // Create the new MTLFunctionConstantValues parameters
                let newFunctionParameters = MTLFunctionConstantValues()
                newFunctionParameters.setConstantValue(&atomRadius, type: .float, index: 0)
                newFunctionParameters.setConstantValue(&probeRadius, type: .float, index: 1)

                // Check if the function needs to be compiled
                if createSASPointsBundle.requiresCompilation(newFunctionParameters: newFunctionParameters) {
                    createSASPointsBundle.compile(functionName: "createSASPoints",
                                                  library: self.library,
                                                  device: self.device,
                                                  constantValues: newFunctionParameters)
                }

                guard let pipelineState = createSASPointsBundle.getPipelineState(functionParameters: newFunctionParameters) else {
                    return
                }

                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(atomSection.length, 1, 1)
                let groupsize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)

                // Set compute pipeline state for current arguments
                computeEncoder.setComputePipelineState(pipelineState)

                // Set buffer contents
                computeEncoder.setBuffer(atomPositionsBuffer,
                                         offset: MemoryLayout<simd_float3>.stride * atomSection.startsAt,
                                         index: 0)
                computeEncoder.setBuffer(generatedSpherePositions,
                                         offset: MemoryLayout<simd_float3>.stride * spherePoints * atomSection.startsAt,
                                         index: 1)

                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)

            }

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()

            // Remove generated points that are inside other spheres

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Create the new MTLFunctionConstantValues parameters
            let newFunctionParameters = MTLFunctionConstantValues()
            newFunctionParameters.setConstantValue(&probeRadius, type: .float, index: 0)

            // Check if the function needs to be compiled
            if removeSASPointsInsideSolidBundle.requiresCompilation(newFunctionParameters: newFunctionParameters) {
                removeSASPointsInsideSolidBundle.compile(functionName: "removeSASPointsInsideSolid",
                                                         library: self.library,
                                                         device: self.device,
                                                         constantValues: newFunctionParameters)
            }

            guard let pipelineState = removeSASPointsInsideSolidBundle.getPipelineState(functionParameters: newFunctionParameters) else {
                return
            }

            // Create atomRadius buffer
            var atomRadius = [Float32]()
            protein.atomIdentifiers.forEach { atomId in
                atomRadius.append(getAtomicRadius(atomType: atomId))
            }
            let atomRadiusBuffer = device.makeBuffer(
                bytes: atomRadius,
                length: protein.atomCount * MemoryLayout<Float32>.stride
            )

            // Create bitmask buffer
            let bitmaskBuffer = device.makeBuffer(
                length: protein.atomCount * spherePoints * MemoryLayout<CBool>.stride
            )

            // Set buffer contents
            computeEncoder.setBuffer(atomPositionsBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(atomRadiusBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(generatedSpherePositions,
                                     offset: 0,
                                     index: 2)
            computeEncoder.setBuffer(bitmaskBuffer,
                                     offset: 0,
                                     index: 3)

            // Kernel arguments
            var atomCount: Int32 = Int32(protein.atomCount)
            computeEncoder.setBytes(&atomCount, length: MemoryLayout<Int32>.stride, index: 4)

            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(protein.atomCount * spherePoints, 1, 1)
            let groupsize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()

            // Add point cloud to scene
            guard let pointsSAS = generatedSpherePositions?.contents().assumingMemoryBound(to: simd_float3.self) else { return }
            guard let bitmask = bitmaskBuffer?.contents().assumingMemoryBound(to: CBool.self) else { return }

            sceneDelegate.addPointCloud(points: pointsSAS,
                                        pointCount: protein.atomCount * spherePoints,
                                        bitmask: bitmask)
        }
    }

    // MARK: - Precompilation

    /// Compiles a given MTLCompiledFunction and modifies the MetalScheduler state atomically.
    ///
    /// This function should be called from a background thread with a ```.background``` QoS,
    /// as the purpose of this class is to pre-emptively compile  Metal functions so they can be
    /// executed faster the first time they're called.
    ///
    /// - Parameters:
    ///   - functionName: The name of the kernel function to compile, from the .metal file.
    ///   - target: The MTLCompiledFunction property from MetalScheduler to compile.
    ///   - newFunctionParameters: The function parameters needed to compile this
    ///   function, ```nil``` if the function takes no arguments.
    private func backgroundAtomicCompile(functionName: String, target: inout MTLCompiledFunction, newFunctionParameters: MTLFunctionConstantValues? = nil) {

        guard target.requiresCompilation(newFunctionParameters: newFunctionParameters) else { return }

        // Compile the function here. This should have been called from a background
        // thread with QoS = .background, to preserve battery.
        let newCompiledFunction = MTLCompiledFunction()
        newCompiledFunction.compile(functionName: functionName,
                                    library: self.library,
                                    device: self.device)
        // Modify the MetalScheduler state synchronously, from the metalDispatchQueue,
        // which is the serial queue used to modify the state. This way, the modified
        // MTLCompiledFunction is changed atomically, and no thread will read it in a
        // partially-written state.
        metalDispatchQueue.sync {
            target = newCompiledFunction
        }

    }

    /// Precompiles and creates pipeline states for the Metal functions that are initiated from UI-driven actions, so we can
    /// avoid compiling and creating their pipelines when they're first called, since that would introduce a delay before the
    /// UI-initiated event is finished.
    private func precompileFunctions() {
        // Don't precompile MTLFunctions when Low Power Mode is enabled, to avoid wasting
        // energy pre-emptively compiling functions that may never be called.
        guard ProcessInfo.processInfo.isLowPowerModeEnabled else {
            return
        }
        // Dispatch the precompilation block on a .background thread, to use the efficiency
        // cores if possible.
        DispatchQueue(label: "Metal precompiler", qos: .background).async {
            // TO-DO: Handle MTLFunctionConstants
            self.backgroundAtomicCompile(functionName: "createSASPoints",
                                         target: &self.createSASPointsBundle)
            self.backgroundAtomicCompile(functionName: "removeSASPointsInsideSolid",
                                         target: &self.removeSASPointsInsideSolidBundle)
        }
    }

}
