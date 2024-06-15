//
//  ProteinMetalView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import SwiftUI
import Metal
import MetalKit

#if os(macOS)
import AppKit
typealias ControllerRepresentable = NSViewControllerRepresentable
#else
import UIKit
typealias ControllerRepresentable = UIViewControllerRepresentable
#endif

struct ProteinMetalView: ControllerRepresentable {
    
    let proteinViewModel: ProteinViewModel
    let selectionModel: SelectionModel

    #if os(iOS)
    typealias UIViewControllerType = ProteinMetalViewController
    
    func makeUIViewController(context: Context) -> ProteinMetalViewController {
        return ProteinMetalViewController(
            proteinViewModel: self.proteinViewModel,
            selectionModel: self.selectionModel
        )
    }

    func updateUIViewController(_ uiViewController: ProteinMetalViewController, context: Context) {
        // TO-DO? Updateable ViewController
    }
    #elseif os(macOS)
    typealias NSViewControllerType = ProteinMetalViewController
    
    func makeNSViewController(context: Context) -> ProteinMetalViewController {
        return ProteinMetalViewController(
            proteinViewModel: self.proteinViewModel,
            selectionModel: self.selectionModel
        )
    }

    func updateNSViewController(_ uiViewController: ProteinMetalViewController, context: Context) {
        // TO-DO? Updateable ViewController
    }
    #endif
}
