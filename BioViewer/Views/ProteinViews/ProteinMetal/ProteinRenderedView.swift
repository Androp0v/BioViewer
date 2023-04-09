//
//  ProteinRenderedView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/4/23.
//

import Foundation
import UIKit

class ProteinRenderedView: UIView {
    
    let renderer: ProteinRenderer
    var metalLayer: CAMetalLayer?
    var displayLink: CADisplayLink?
    
    init(renderer: ProteinRenderer, frame: CGRect) {
        self.renderer = renderer
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override final class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
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
    
    override func didMoveToWindow() {
        
        guard let renderThread = renderer.renderThread else { return }
        
        // Remove CADisplayLink if there was one already running
        if displayLink != nil {
            perform(
                #selector(removeDisplayLink),
                on: renderThread,
                with: nil,
                waitUntilDone: false
            )
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(render))
        
        // Receive CADisplayLink calls on a custom non-main thread
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
    
    @objc func removeDisplayLink() {
        displayLink?.remove(from: .current, forMode: .default)
    }
    
    @objc func addDisplayLink() {
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc func render() {
        guard let metalLayer else {
            return
        }
        renderer.draw(in: metalLayer)
    }
}
