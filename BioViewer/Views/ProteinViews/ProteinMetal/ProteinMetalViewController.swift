//
//  ProteinMetalViewController.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import UIKit
import Metal
import MetalKit
import simd

class ProteinMetalViewController: UIViewController {

    var device: MTLDevice!
    
    var renderedView: ProteinRenderedView!
    
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
        renderedView = ProteinRenderedView(
            renderer: proteinViewModel.renderer,
            frame: view.frame
        )
        renderedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderedView)
        NSLayoutConstraint.activate([
            renderedView.topAnchor.constraint(equalTo: view.topAnchor),
            renderedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderedView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        // FIXME: This breaks PhotoMode, but would be useful
        /*if #available(iOS 16.0, *) {
            if device.supportsFamily(.apple1) {
                renderedView.depthStencilStorageMode = .memoryless
            } else {
                renderedView.depthStencilStorageMode = .private
            }
        }*/

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
            Task {
                let currentCameraPosition = await self.proteinViewModel.renderer.mutableState.scene.cameraPosition
                // TO-DO: Proper zooming
                let newDistance = currentCameraPosition.z / Float(gestureRecognizer.scale)
                await self.proteinViewModel.renderer.mutableState.scene.updateCameraDistanceToModel(
                    distanceToModel: newDistance,
                    newBoundingSphere: nil
                )
                gestureRecognizer.scale = 1.0
            }
       }
    }
    
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let toolbarConfig = proteinViewModel.toolbarConfig else { return }
        
        if toolbarConfig.autorotating {
            proteinViewModel.toolbarConfig?.autorotating = false
        }
        
        if gestureRecognizer.state == .changed {
            switch toolbarConfig.selectedTool {
            case CameraControlTool.rotate:
                Task {
                    let rotationSpeedX = Float(gestureRecognizer.velocity(in: renderedView).x) / 5000
                    let rotationSpeedY = Float(gestureRecognizer.velocity(in: renderedView).y) / 5000
                    
                    var currentRotationMatrix = await self.proteinViewModel.renderer.mutableState.scene.userModelRotationMatrix
                    
                    // Revert the axis rotation before rotating through that axis
                    currentRotationMatrix *= Transform.rotationMatrix(
                        radians: -rotationSpeedX,
                        axis: (currentRotationMatrix.inverse * simd_float4(0, 1, 0, 1)).xyz
                    )
                    currentRotationMatrix *= Transform.rotationMatrix(
                        radians: -rotationSpeedY,
                        axis: (currentRotationMatrix.inverse * simd_float4(1, 0, 0, 1)).xyz
                    )
                    
                    await self.proteinViewModel.renderer.mutableState.scene.userModelRotationMatrix = currentRotationMatrix
                }
                
            case CameraControlTool.move:
                Task {
                    // TO-DO: Improve move tool
                    #if targetEnvironment(macCatalyst)
                    var translationSensitivity: Float = 0.000005
                    #else
                    var translationSensitivity: Float = 0.00001
                    #endif
                    
                    // Move should be less sensible the closer the camera is to the protein
                    await translationSensitivity *= proteinViewModel.renderer.mutableState.scene.cameraPosition.z
                    
                    let translationX = Float(gestureRecognizer.velocity(in: renderedView).x) * translationSensitivity
                    let translationY = Float(gestureRecognizer.velocity(in: renderedView).y) * translationSensitivity
                    await self.proteinViewModel.renderer.mutableState.scene.translateCamera(x: translationX, y: -translationY)
                }
            
            default:
                break
            }
        }
    }

}
