//
//  MetalScheduler.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

import Foundation
import Metal

class MetalScheduler {

    // MARK: - Properties

    static let shared = MetalScheduler()

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

    public func createSASPoints() {
        metalDispatchQueue.sync {
            // Check if the function needs to be compiled
            if createSASPointsBundle.requiresCompilation(newFunctionParameters: nil) {
                createSASPointsBundle.compile(functionName: "createSASPoints",
                                              library: self.library,
                                              device: self.device)
            }
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

        if target.requiresCompilation(newFunctionParameters: newFunctionParameters) {
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

    }

    /// Precompiles and creates pipeline states for the Metal functions that are initiated from UI-driven actions, so we can
    /// avoid compiling and creating their pipelines when they're first called, since that would introduce a delay before the
    /// UI-initiated event is finished.
    private func precompileFunctions() {
        DispatchQueue(label: "Metal precompiler", qos: .background).async {
            self.backgroundAtomicCompile(functionName: "createSASPoints",
                                         target: &self.createSASPointsBundle)
            self.backgroundAtomicCompile(functionName: "removeSASPointsInsideSolid",
                                         target: &self.removeSASPointsInsideSolidBundle)
        }
    }

}
