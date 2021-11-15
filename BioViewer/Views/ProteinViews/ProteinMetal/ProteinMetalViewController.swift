//
//  ProteinMetalViewController.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import UIKit
import Metal
import MetalKit

class ProteinMetalViewController: UIViewController {

    var device: MTLDevice!

    var renderedView: MTKView!
    weak var renderDelegate: MTKViewDelegate?
    var proteinViewModel: ProteinViewModel

    init(proteinViewModel: ProteinViewModel) {
        self.proteinViewModel = proteinViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.device = device

        // Setup MTKView
        renderedView = MTKView(frame: view.frame, device: device)
        renderedView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        renderedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderedView)
        NSLayoutConstraint.activate([
            renderedView.topAnchor.constraint(equalTo: view.topAnchor),
            renderedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderedView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        // Render delegate
        self.renderDelegate = proteinViewModel.renderer
        renderedView.delegate = self.renderDelegate

        // Create depth texture for view
        renderedView.depthStencilPixelFormat = .depth32Float

        // Add gesture recognition
        renderedView.isUserInteractionEnabled = true
        
        // MARK: - Gesture recognizers
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch))
        renderedView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        renderedView.addGestureRecognizer(panGesture)

    }

    // MARK: - Private functions

    @objc private func handlePinch(gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            // TO-DO: Proper zooming
            self.proteinViewModel.renderer.scene.cameraPosition.z /= Float(gestureRecognizer.scale)
            gestureRecognizer.scale = 1.0
       }
    }
    
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .changed {
            let rotationSpeedX = Float(gestureRecognizer.velocity(in: renderedView).x) / 5000
            let rotationSpeedY = Float(gestureRecognizer.velocity(in: renderedView).y) / 5000
            // Revert the axis rotation before rotating through that axis
            self.proteinViewModel.renderer.scene.userModelRotationMatrix *= Transform.rotationMatrix(radians: -rotationSpeedX, axis: (self.proteinViewModel.renderer.scene.userModelRotationMatrix.inverse * simd_float4(0, 1, 0, 1)).xyz )
            self.proteinViewModel.renderer.scene.userModelRotationMatrix *= Transform.rotationMatrix(radians: -rotationSpeedY, axis: (self.proteinViewModel.renderer.scene.userModelRotationMatrix.inverse * simd_float4(1, 0, 0, 1)).xyz )
        }
    }

}
