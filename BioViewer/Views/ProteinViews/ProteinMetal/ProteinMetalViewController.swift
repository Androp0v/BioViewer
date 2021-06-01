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

    var renderView: MTKView!
    var renderDelegate: MTKViewDelegate?

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.device = device

        // Setup MTKView
        renderView = MTKView(frame: view.frame, device: device)
        renderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            renderView.topAnchor.constraint(equalTo: view.topAnchor),
            renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        // Render delegate
        self.renderDelegate = BasicRenderer(device: self.device)
        renderView.delegate = self.renderDelegate

    }

}
