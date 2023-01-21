//
//  FileAtomElementPopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import SwiftUI

private enum CompositionOption: PickableEnum {
    case element
    case residue
    
    var displayName: String {
        switch self {
        case .element: return "Element"
        case .residue: return "Residue"
        }
    }
}

struct ProteinCompositionView: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var compositionOption: CompositionOption = .element
    @State private var segments = [InfoCapsuleSegment]()
    @State private var elementComposition = ProteinElementComposition()
    @State private var residueComposition = ProteinResidueComposition()
    
    private enum AnimationConstants {
        static let duration: Double = 0.8
    }
        
    var body: some View {
        ScrollView {
            VStack {
                
                HStack(spacing: .zero) {
                    Spacer()
                    Text(NSLocalizedString("Atoms of each", comment: ""))
                    BioViewerPicker(selection: $compositionOption)
                    Spacer()
                }
                .padding(.top)
                
                ZStack {
                    ForEach(segments.reversed(), id: \.self) { segment in
                        Circle()
                            .trim(from: 0, to: segment.fraction)
                            .stroke(
                                segment.color,
                                style: StrokeStyle(lineWidth: 40)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                }
                .padding(.horizontal, 24)
                .frame(width: 250, height: 250)
                .onAppear {
                    computeFractions()
                }
                .onChange(of: compositionOption) { _ in
                    withAnimation {
                        computeFractions()
                    }
                }
                VStack {
                    Divider()
                    
                    ForEach(AtomElement.importantElements, id: \.self) { element in
                        FileAtomElementRow(element: element)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    ForEach(AtomElement.otherElements.filter({ elementComposition.elementCounts.keys.contains($0) }), id: \.self) { element in
                        FileAtomElementRow(element: element)
                    }
                    FileAtomElementRow(element: .unknown)
                    
                    Divider()
                    
                    FileAtomTotalsRow()
                }
                .environmentObject(proteinViewModel)
                .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 350, minHeight: 550)
    }
    
    // MARK: - Fractions
    
    func computeFractions() {
        guard let file = proteinViewModel.dataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
        var newSegments = [InfoCapsuleSegment]()

        switch compositionOption {
        case .element:
            elementComposition = ProteinElementComposition()
            for protein in proteins {
                elementComposition += protein.elementComposition
            }
            var importantTotal: Double = 0.0
            for element in AtomElement.importantElements {
                let elementFraction = Double(elementComposition.elementCounts[element] ?? 0) / Double(elementComposition.totalCount)
                newSegments.append(InfoCapsuleSegment(
                    fraction: elementFraction + importantTotal,
                    color: proteinViewModel.elementColors[Int(element.rawValue)]
                ))
                importantTotal += elementFraction
            }
            newSegments.append(InfoCapsuleSegment(
                fraction: 1 - importantTotal,
                color: proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
            ))
        case .residue:
            residueComposition = ProteinResidueComposition()
            for proteinResidues in proteins.compactMap({ $0.residueComposition }) {
                residueComposition += proteinResidues
            }
            var currentTotal: Double = 0.0
            for residue in Residue.allCases {
                let residueFraction = Double(residueComposition.residueCounts[residue] ?? 0) / Double(residueComposition.totalCount)
                newSegments.append(InfoCapsuleSegment(
                    fraction: residueFraction + currentTotal,
                    color: proteinViewModel.residueColors[Int(residue.rawValue)]
                ))
                currentTotal += residueFraction
            }
        }
        
        self.segments = newSegments
    }
}

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        ProteinCompositionView()
    }
}
