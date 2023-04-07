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
    var depthTexture = ProteinRenderedViewDepthTexture()
    
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
        let displayScale = window?.windowScene?.screen.scale ?? 1.0
        let size = CGSize(
            width: frame.width * displayScale,
            height: frame.height * displayScale
        )
        depthTexture.makeTextures(
            device: renderer.device,
            textureWidth: Int(size.width),
            textureHeight: Int(size.height)
        )
        guard let metalLayer = self.layer as? CAMetalLayer else {
            return
        }
        self.metalLayer = metalLayer
        metalLayer.contentsScale = displayScale
        self.contentScaleFactor = displayScale
        renderer.drawableSizeChanged(to: size)
    }
    
    override func didMoveToWindow() {
        // FIXME: Update on display changes
        displayLink = CADisplayLink(target: self, selector: #selector(render))
        perform(
            #selector(addDisplayLink),
            on: renderer.renderThread!,
            with: nil,
            waitUntilDone: false
        )
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120)
        guard let metalLayer = self.layer as? CAMetalLayer else {
            return
        }
        metalLayer.device = renderer.device
    }
    
    @objc func addDisplayLink() {
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc func render() {
        guard let metalLayer else {
            return
        }
        guard let depthTexture = depthTexture.depthTexture else {
            return
        }
        renderer.draw(in: metalLayer, depthTexture: depthTexture)
    }
}
