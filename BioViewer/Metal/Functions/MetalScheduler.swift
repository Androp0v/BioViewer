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

    let device: MTLDevice!
    let queue: MTLCommandQueue?
    let library: MTLLibrary?

    // PipelineStateBundle bundles
    var createSphereModelBundle = PipelineStateBundle()
    var createSASPointsBundle = PipelineStateBundle()
    var removeSASPointsInsideSolidBundle = PipelineStateBundle()

    /// DispatchQueue for synchronization
    private(set) var metalDispatchQueue: DispatchQueue

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

    // MARK: - Precompilation

    /// Builds a given PipelineStateBundle and modifies the MetalScheduler state atomically.
    ///
    /// This function should be called from a background thread with a ```.background``` QoS,
    /// as the purpose of this class is to pre-emptively compile  Metal functions so they can be
    /// executed faster the first time they're called.
    ///
    /// - Parameters:
    ///   - functionName: The name of the kernel function to compile, from the .metal file.
    ///   - target: The PipelineStateBundle property from MetalScheduler to compile.
    ///   - newFunctionParameters: The function parameters needed to compile this
    ///   function, ```nil``` if the function takes no arguments.
    private func backgroundAtomicCompile(functionName: String, target: inout PipelineStateBundle, newFunctionParameters: MTLFunctionConstantValues? = nil) {

        guard target.requiresBuilding(newFunctionParameters: newFunctionParameters) else { return }

        // Build the pipeline state here. This should have been called from a background
        // thread with QoS = .background, to preserve battery.
        let newPipelineState = PipelineStateBundle()
        newPipelineState.createPipelineState(functionName: functionName,
                                                library: self.library,
                                                device: self.device)
        // Modify the MetalScheduler state synchronously, from the metalDispatchQueue,
        // which is the serial queue used to modify the state. This way, the modified
        // PipelineStateBundle is changed atomically, and no thread will read it in a
        // partially-written state.
        metalDispatchQueue.sync {
            target = newPipelineState
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
