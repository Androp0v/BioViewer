//
//  MTLCompiledFunction.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

import Foundation
import Metal

class MTLCompiledFunction {
    var function: MTLFunction?
    var pipelineState: MTLComputePipelineState?
    var functionParameters: MTLFunctionConstantValues?

    /// Wether or not this MTLCompiledFunction needs to be compiled (because it has not
    /// been compiled yet, or because the constant values have changed).
    func requiresCompilation(newFunctionParameters: MTLFunctionConstantValues?) -> Bool {
        if function == nil {
            return true
        }
        if pipelineState == nil {
            return true
        }
        if newFunctionParameters != functionParameters {
            return true
        }
        return false
    }

    func compile(functionName: String, library: MTLLibrary?, device: MTLDevice, constantValues: MTLFunctionConstantValues? = nil) {

        guard let library = library else { return }

        // Compile the function with the constant values (if any)
        var compiledFunction: MTLFunction?
        if let constantValues = constantValues {
            compiledFunction = try? library.makeFunction(name: functionName, constantValues: constantValues)
        } else {
            compiledFunction = library.makeFunction(name: functionName)
        }
        guard let compiledFunction = compiledFunction else { return }

        // Create the pipeline state
        guard let pipelineState = try? device.makeComputePipelineState(function: compiledFunction) else { return }

        // Assign the compiled result to self
        self.function = compiledFunction
        self.pipelineState = pipelineState
    }
}
