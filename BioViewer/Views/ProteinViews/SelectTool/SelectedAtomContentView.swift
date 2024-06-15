//
//  SelectedAtomContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/3/24.
//

import SwiftUI

@MainActor struct SelectedAtomContentView: View {
    
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
    var radiusString: String {
        guard let element = selectionModel.elementHit else {
            return "- Å"
        }
        let radius = AtomRadii.vanDerWaals.getRadiusOf(atomElement: element)
        return "\(numberFormatter.string(from: NSNumber(floatLiteral: Double(radius))) ?? "-") Å"
    }
    
    var elementColor: Color {
        guard let element = selectionModel.elementHit else {
            return .gray
        }
        return colorViewModel.elementColors[Int(element.rawValue)]
    }
    var chainColor: Color {
        guard let chain = selectionModel.chainHit else {
            return .gray
        }
        return colorViewModel.chainColors[Int(chain.rawValue)]
    }
    var residueColor: Color {
        guard let residue = selectionModel.residueHit else {
            return .gray
        }
        return colorViewModel.residueColors[Int(residue.rawValue)]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
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
                VStack(alignment: .leading) {
                    infoRow(color: elementColor, name: selectionModel.elementHit?.longName)
                    infoRow(color: chainColor, name: selectionModel.chainHit?.displayName)
                    infoRow(color: residueColor, name: selectionModel.residueHit?.name)
                }
            }
            
            Divider()
            
            HStack {
                Text("Radius:")
                Text(radiusString)
                    .font(.footnote)
                    .monospaced()
            }
            HStack {
                Text("Coordinates:")
                CoordinatesView(selectionModel.coordinatesHit)
            }
            
            #if DEBUG
            SelectedDebugView()
            #endif
        }
        .padding(.horizontal)
        .padding(.bottom)
        .drawingGroup()
    }
    
    @ViewBuilder func infoRow(color: Color, name: String?) -> some View {
        HStack {
            Circle()
                .stroke(
                    Color.separator,
                    style: StrokeStyle(lineWidth: 1)
                )
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(name ?? "-")")
        }
    }
}
