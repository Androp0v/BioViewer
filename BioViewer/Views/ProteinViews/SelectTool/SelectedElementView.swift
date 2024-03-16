//
//  SelectedElementView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import SwiftUI

@MainActor struct SelectedElementView: View {
    
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    
    private let numberFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var elementSymbol: String {
        selectionModel.elementHit?.name ?? "?"
    }
    var elementName: String {
        selectionModel.elementHit?.longName ?? "?"
    }
    var elementColor: Color {
        guard let element = selectionModel.elementHit else {
            return .gray
        }
        return colorViewModel.elementColors[Int(element.rawValue)]
    }
    var radiusString: String {
        guard let element = selectionModel.elementHit else {
            return "- Å"
        }
        let radius = AtomRadii.vanDerWaals.getRadiusOf(atomElement: element)
        return "\(numberFormatter.string(from: NSNumber(floatLiteral: Double(radius))) ?? "-") Å"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: .zero) {
            ZStack {
                Rectangle()
                    .frame(width: 64, height: 64)
                    .foregroundColor(elementColor)
                    .saturation(0.8)
                Rectangle()
                    .strokeBorder(
                        Color.primary,
                        lineWidth: 2
                    )
                    .frame(width: 64, height: 64)
                Text(elementSymbol)
                    .font(.largeTitle)
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(elementName)
                        .bold()
                }
                
                Divider()
                    .padding(.bottom, 4)
                
                HStack {
                    Text("Radius:")
                    Text(radiusString)
                        .font(.footnote)
                        .monospaced()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coordinates:")
                    CoordinatesView(selectionModel.coordinatesHit)
                }
            }
            .padding(.leading)
            
            Spacer()
        }
        .padding(.top, 4)
        .padding(.horizontal)
        .padding(.bottom)
        .drawingGroup()
    }
}

#Preview {
    SelectedElementView()
}
