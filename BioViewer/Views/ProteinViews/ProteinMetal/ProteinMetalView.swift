//
//  ProteinMetalView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import SwiftUI
import Metal
import MetalKit

struct ProteinMetalView: UIViewControllerRepresentable {

    typealias UIViewControllerType = ProteinMetalViewController

    let proteinViewModel: ProteinViewModel
    let selectionModel: SelectionModel

    func makeUIViewController(context: Context) -> ProteinMetalViewController {
        return ProteinMetalViewController(
            proteinViewModel: self.proteinViewModel,
            selectionModel: self.selectionModel
        )
    }

    func updateUIViewController(_ uiViewController: ProteinMetalViewController, context: Context) {
        // TO-DO? Updateable ViewController
    }

}
