//
//  ProteinRenderedView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/4/23.
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class ProteinRenderedView: PlatformView {
    
    nonisolated(unsafe) let renderer: ProteinRenderer
    nonisolated(unsafe) private var renderThread: Thread?
    nonisolated(unsafe) var metalLayer: CAMetalLayer?
    var displayLink: PlatformDisplayLink?
    
    init(renderer: ProteinRenderer, frame: CGRect) {
        self.renderer = renderer
        super.init(frame: frame)
        
        startRenderThread()
        
        #if os(macOS)
        self.wantsLayer = true
        self.metalLayer = CAMetalLayer()
        self.layer = metalLayer
        self.layer?.delegate = self
        #endif
    }
    
    private func startRenderThread() {
        // Setup render thread
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(iOS)
    override final class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    #elseif os(macOS)
    override func makeBackingLayer() -> CALayer {
        return CAMetalLayer()
    }
    #endif
    
    #if os(iOS)
    // Called when view size changes. Update drawables and textures
    // accordingly.
    override func layoutSubviews() {
        var displayScale: CGFloat
        if let screen = window?.windowScene?.screen {
            displayScale = screen.scale
        } else {
            displayScale = 1.0
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "ProteinRenderedView failed to get display scale."
            )
        }
        let size = CGSize(
            width: frame.width * displayScale,
            height: frame.height * displayScale
        )
        guard let metalLayer = self.layer as? CAMetalLayer else {
            return
        }
        self.metalLayer = metalLayer
        renderer.drawableSizeChanged(to: size, layer: metalLayer, displayScale: displayScale)
    }
    #elseif os(macOS)
    // Called when view size changes. Update drawables and textures
    // accordingly.
    override func layout() {
        var displayScale: CGFloat
        if let screen = window?.screen {
            displayScale = screen.backingScaleFactor
        } else {
            displayScale = 1.0
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "ProteinRenderedView failed to get display scale."
            )
        }
        let size = CGSize(
            width: frame.width * displayScale,
            height: frame.height * displayScale
        )
        guard let metalLayer = self.layer as? CAMetalLayer else {
            return
        }
        self.metalLayer = metalLayer
        renderer.drawableSizeChanged(to: size, layer: metalLayer, displayScale: displayScale)
    }
    #endif
    
    #if os(iOS)
    override func didMoveToWindow() {
        
        guard let renderThread = self.renderThread else { return }
        
        // Remove PlatformDisplayLink if there was one already running
        if displayLink != nil {
            perform(
                #selector(removeDisplayLink),
                on: renderThread,
                with: nil,
                waitUntilDone: false
            )
        }
        
        displayLink = PlatformDisplayLink {
            self.render()
        }
        
        // Receive PlatformDisplayLink calls on a custom non-main thread
        perform(
            #selector(addDisplayLink),
            on: renderThread,
            with: nil,
            waitUntilDone: false
        )
        
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120)
        Task {
            guard let metalLayer = self.layer as? CAMetalLayer else {
                return
            }
            metalLayer.device = await renderer.device
            metalLayer.framebufferOnly = false
        }
    }
    #elseif os(macOS)
    override func viewDidMoveToWindow() {
        guard let renderThread = self.renderThread else { return }
        
        // Remove PlatformDisplayLink if there was one already running
        if displayLink != nil {
            perform(
                #selector(removeDisplayLink),
                on: renderThread,
                with: nil,
                waitUntilDone: false
            )
        }
        
        displayLink = PlatformDisplayLink(in: self.window?.screen) {
            self.render()
        }
        
        // Receive PlatformDisplayLink calls on a custom non-main thread
        perform(
            #selector(addDisplayLink),
            on: renderThread,
            with: nil,
            waitUntilDone: false
        )
        
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120)
        guard let metalLayer = self.layer as? CAMetalLayer else {
            return
        }
        metalLayer.device = renderer.device
        metalLayer.framebufferOnly = false
    }
    #endif
    
    @objc func removeDisplayLink() {
        displayLink?.remove(from: .current, forMode: .default)
    }
    
    @objc func addDisplayLink() {
        displayLink?.add(to: .current, forMode: .default)
    }
    
    nonisolated func render() {
        guard let metalLayer else {
            return
        }
        Task(priority: .high) {
            await renderer.draw(in: metalLayer)
        }
    }
}

#if os(macOS)
extension ProteinRenderedView: CALayerDelegate {}
#endif
