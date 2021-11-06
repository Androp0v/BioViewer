//
//  PipelineStateBundle.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

import Foundation
import Metal

class PipelineStateBundle {

    // MARK: - Properties

    var function: MTLFunction?

    /// MTLComputePipeline state for the function with no constant parameters
    var pipelineStateNoOptions: MTLComputePipelineState?

    /// Cached dictionary of MTLComputePipeline objects for a given constant function parameter.
    var pipelineStates = [MTLFunctionConstantValues: MTLComputePipelineState]()

    // MARK: - Public functions

    /// Retrieve the pipeline state for a given set of MTLFunctionConstantValues
    func getPipelineState(functionParameters: MTLFunctionConstantValues?) -> MTLComputePipelineState? {
        guard let functionParameters = functionParameters else { return pipelineStateNoOptions }
        return pipelineStates[functionParameters]
    }

    /// Wether or not this PipelineStateBundle needs to be built (because it has not
    /// been built yet, or because the constant values have changed).
    func requiresBuilding(newFunctionParameters: MTLFunctionConstantValues?) -> Bool {

        // If the function does not exist we need to create it.
        if function == nil {
            return true
        }

        if let newFunctionParameters = newFunctionParameters {
            // If the function has newFunctionParameters, check if the
            // parameters have an associated MTLComputePipelineState
            // cached in the dictionary.

            if pipelineStates[newFunctionParameters] == nil {
                // If there's no pipeline state for this set of
                // parameters, a compilation is required.
                return true
            }
            // If a pipeline state does exist for this parameters,
            // there's no need to recompile.
            return false
        } else {
            // If the function has no function constants, we only
            // need to check that pipelineStateNoOptions exists
            if pipelineStateNoOptions == nil {
                return true
            }
            return false
        }
    }

    func createPipelineState(functionName: String, library: MTLLibrary?, device: MTLDevice, constantValues: MTLFunctionConstantValues? = nil) {

        guard let library = library else { return }

        // Create the function with the constant values (if any)
        var compiledFunction: MTLFunction?
        if let constantValues = constantValues {
            guard let compiledFunction = try? library.makeFunction(name: functionName, constantValues: constantValues) else {
                NSLog("Failed to make compute function \(functionName)")
                return
            }

            guard let pipelineState = try? device.makeComputePipelineState(function: compiledFunction) else {
                NSLog("Failed to compile compute pipeline state for  \(functionName)")
                return
            }

            // Cache the pipeline state for the given parameters
            self.pipelineStates[constantValues] = pipelineState
        } else {
            compiledFunction = library.makeFunction(name: functionName)

            guard let compiledFunction = compiledFunction else { return }

            // Create the pipeline state (compilation optimizations for
            // MTLConstantFunctions happen here).
            guard let pipelineState = try? device.makeComputePipelineState(function: compiledFunction) else {
                return
            }

            // Assign the compiled result to self
            self.function = compiledFunction

            // Assign or cache the pipeline state for the given parameters
            self.pipelineStateNoOptions = pipelineState
        }
    }
}
