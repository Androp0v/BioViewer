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

    func makeUIViewController(context: Context) -> ProteinMetalViewController {
        return ProteinMetalViewController()
    }

    func updateUIViewController(_ uiViewController: ProteinMetalViewController, context: Context) {
        // TO-DO? Updateable ViewController
    }

}

struct ProteinMetalView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinMetalView()
    }
}
