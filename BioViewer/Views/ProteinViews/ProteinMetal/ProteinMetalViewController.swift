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
    var selectionModel: SelectionModel
    
    init(proteinViewModel: ProteinViewModel, selectionModel: SelectionModel) {
        self.proteinViewModel = proteinViewModel
        self.selectionModel = selectionModel
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        renderedView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch))
        renderedView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        renderedView.addGestureRecognizer(panGesture)

    }

    // MARK: - Private functions
    
    @objc private func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.view)
        Task(priority: .userInitiated) {
            await self.selectionModel.hit(
                at: location,
                viewSize: self.view.frame.size,
                camera: self.proteinViewModel.renderer.mutableState.getCamera(),
                cameraPosition: self.proteinViewModel.renderer.mutableState.getCameraPosition(),
                rotationQuaternion: self.proteinViewModel.renderer.mutableState.getUserRotationQuaternion(),
                modelTranslationMatrix: self.proteinViewModel.renderer.mutableState.getModelTranslationMatrix(),
                atomRadii: self.proteinViewModel.renderer.mutableState.getAtomRadii(),
                dataSource: self.proteinViewModel.dataSource
            )
        }
    }

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
    
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let toolbarConfig = proteinViewModel.toolbarConfig else { return }
        
        if toolbarConfig.autorotating {
            proteinViewModel.toolbarConfig?.autorotating = false
        }
        
        if gestureRecognizer.state == .changed {
            switch toolbarConfig.selectedTool {
            case CameraControlTool.rotate:
                Task {
                    let rawRotationSpeed: CGPoint = gestureRecognizer.velocity(in: renderedView)
                    guard rawRotationSpeed != .zero else { return }
                    let rotationSpeedX = rawRotationSpeed.x / 10000
                    let rotationSpeedY = rawRotationSpeed.y / 10000
                    
                    let currentRotationQuaternion = await self.proteinViewModel.renderer.mutableState.getUserRotationQuaternion()
                    
                    let rotationAxis = normalize(rotationSpeedX * simd_double3(0, 1, 0) + rotationSpeedY * simd_double3(1, 0, 0))
                    let newRotationQuaternion = simd_quatd(
                        angle: -sqrt(pow(rotationSpeedX, 2) + pow(rotationSpeedY, 2)),
                        axis: rotationAxis
                    )
                    
                    await self.proteinViewModel.renderer.mutableState.setUserRotationQuaternion(
                        newRotationQuaternion * currentRotationQuaternion
                    )
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
                    await translationSensitivity *= proteinViewModel.renderer.mutableState.getCameraPosition().z
                    
                    let translationX = Float(gestureRecognizer.velocity(in: renderedView).x) * translationSensitivity
                    let translationY = Float(gestureRecognizer.velocity(in: renderedView).y) * translationSensitivity
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
