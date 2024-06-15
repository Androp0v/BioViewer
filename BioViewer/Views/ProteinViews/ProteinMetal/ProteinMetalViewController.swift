//
//  ProteinMetalViewController.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Metal
import MetalKit
import simd

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class ProteinMetalViewController: PlatformViewController {

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
        #if os(iOS)
        renderedView.isUserInteractionEnabled = true
        #endif
        
        // MARK: - Gesture recognizers
        
        #if os(iOS)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        #elseif os(macOS)
        let pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(self.handlePinch))
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        #endif
        renderedView.addGestureRecognizer(pinchGesture)
        renderedView.addGestureRecognizer(panGesture)
    }

    // MARK: - Pinch
    
    #if os(iOS)
    @objc private func handlePinch(gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            Task {
                let currentCameraPosition = await self.proteinViewModel.renderer.mutableState.getCameraPosition()
                // TO-DO: Proper zooming
                let newDistance = currentCameraPosition.z / Float(gestureRecognizer.scale)
                await self.proteinViewModel.renderer.mutableState.setCameraDistanceToModel(newDistance)
                gestureRecognizer.scale = 1.0
            }
       }
    }
    #elseif os(macOS)
    @objc private func handlePinch(gestureRecognizer: NSMagnificationGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            Task {
                let currentCameraPosition = await self.proteinViewModel.renderer.mutableState.getCameraPosition()
                // TO-DO: Proper zooming
                let newDistance = currentCameraPosition.z / Float(gestureRecognizer.magnification + 1.0)
                await self.proteinViewModel.renderer.mutableState.setCameraDistanceToModel(newDistance)
            }
       }
    }
    #endif
    
    // MARK: - Pan
    
    #if os(iOS)
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        self.genericHandlePan(gestureRecognizer: gestureRecognizer)
    }
    #elseif os(macOS)
    @objc private func handlePan(gestureRecognizer: NSPanGestureRecognizer) {
        self.genericHandlePan(gestureRecognizer: gestureRecognizer)
    }
    #endif
    
    private func genericHandlePan(gestureRecognizer: some PlatformPanGestureRecognizer) {
        
        guard let toolbarConfig = proteinViewModel.toolbarConfig else { return }
        
        if toolbarConfig.autorotating {
            proteinViewModel.toolbarConfig?.autorotating = false
        }
        
        if gestureRecognizer.stateChanged {
            switch toolbarConfig.selectedTool {
            case CameraControlTool.rotate:
                Task(priority: .high) {
                    let rotationSpeedX = Float(gestureRecognizer.velocity(in: renderedView).x) / 5000
                    #if os(iOS)
                    let rotationSpeedY = Float(gestureRecognizer.velocity(in: renderedView).y) / 5000
                    #elseif os(macOS)
                    // Swap rotation direction on macOS to match iOS
                    let rotationSpeedY = -Float(gestureRecognizer.velocity(in: renderedView).y) / 5000
                    #endif
                    
                    var currentRotationMatrix = await self.proteinViewModel.renderer.mutableState.getUserRotationMatrix()
                    
                    // Revert the axis rotation before rotating through that axis
                    currentRotationMatrix *= Transform.rotationMatrix(
                        radians: -rotationSpeedX,
                        axis: (currentRotationMatrix.inverse * simd_float4(0, 1, 0, 1)).xyz
                    )
                    currentRotationMatrix *= Transform.rotationMatrix(
                        radians: -rotationSpeedY,
                        axis: (currentRotationMatrix.inverse * simd_float4(1, 0, 0, 1)).xyz
                    )
                    
                    await self.proteinViewModel.renderer.mutableState.setUserRotationMatrix(currentRotationMatrix)
                }
                
            case CameraControlTool.move:
                Task {
                    // TO-DO: Improve move tool
                    #if os(iOS)
                    #if targetEnvironment(macCatalyst)
                    var translationSensitivity: Float = 0.000005
                    #else
                    var translationSensitivity: Float = 0.00001
                    #endif
                    #elseif os(macOS)
                    var translationSensitivity: Float = 0.0000025
                    #endif
                    
                    // Move should be less sensible the closer the camera is to the protein
                    await translationSensitivity *= proteinViewModel.renderer.mutableState.getCameraPosition().z
                    
                    let translationX = Float(gestureRecognizer.velocity(in: renderedView).x) * translationSensitivity
                    #if os(iOS)
                    let translationY = Float(gestureRecognizer.velocity(in: renderedView).y) * translationSensitivity
                    #elseif os(macOS)
                    // Swap translation direction on macOS to match iOS
                    let translationY = -Float(gestureRecognizer.velocity(in: renderedView).y) * translationSensitivity
                    #endif
                    
                    await self.proteinViewModel.renderer.mutableState.translateCameraXY(
                        x: translationX,
                        y: -translationY
                    )
                }
            
            default:
                break
            }
        }
    }
}
