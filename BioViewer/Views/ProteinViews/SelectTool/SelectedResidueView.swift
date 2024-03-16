//
//  SelectedResidueView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/2/24.
//

import SwiftUI

@MainActor struct SelectedResidueView: View {
    
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    
    var residueColor: Color {
        guard let residue = selectionModel.residueHit else {
            return .gray
        }
        return colorViewModel.residueColors[Int(residue.rawValue)]
    }
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .stroke(
                        Color(uiColor: .separator),
                        style: StrokeStyle(lineWidth: 1)
                    )
                    .fill(residueColor)
                    .frame(width: 8, height: 8)
                Text("\(selectionModel.residueHit?.name ?? "-")")
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    SelectedResidueView()
}
