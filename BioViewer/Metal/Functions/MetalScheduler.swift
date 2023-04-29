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
    var createBondsBundle = PipelineStateBundle()
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

        // Create a queue to dispatch metal work (FIFO) to synchronize work
        metalDispatchQueue = DispatchQueue.init(label: "Metal Scheduler", qos: .default)
    }
}
