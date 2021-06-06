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

    func makeUIViewController(context: Context) -> ProteinMetalViewController {
        return ProteinMetalViewController(proteinViewModel: self.proteinViewModel)
    }

    func updateUIViewController(_ uiViewController: ProteinMetalViewController, context: Context) {
        // TO-DO? Updateable ViewController
    }

}

struct ProteinMetalView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinMetalView(proteinViewModel: ProteinViewModel())
    }
}
