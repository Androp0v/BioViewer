//
//  SelectedChainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/2/24.
//

import SwiftUI

@MainActor struct SelectedChainView: View {
    
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    
    var chainColor: Color {
        guard let chain = selectionModel.chainHit else {
            return .gray
        }
        return colorViewModel.chainColors[Int(chain.rawValue)]
    }
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .stroke(
                        Color(uiColor: .separator),
                        style: StrokeStyle(lineWidth: 1)
                    )
                    .background {
                        Circle()
                            .foregroundColor(chainColor)
                    }
                    .frame(width: 8, height: 8)
                Text("\(selectionModel.chainHit?.displayName ?? "-")")
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    SelectedChainView()
}
