//
//  FileCompositionView.swift
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

private struct CompositionItem: Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let count: Int
    let fraction: Double
}

struct FileCompositionView: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    @State private var compositionOption: CompositionOption = .element
    @State private var circleSegments = [InfoCapsuleSegment]()
    @State private var listSegments = [[CompositionItem]]()
    @State private var elementComposition = ProteinElementComposition()
    @State private var residueComposition = ProteinResidueComposition()
    
    private enum AnimationConstants {
        static let duration: Double = 0.8
    }
        
    var body: some View {
        VStack(spacing: .zero) {
            
            HStack(spacing: 8) {
                Spacer()
                Text(NSLocalizedString("Atoms of each", comment: ""))
                BioViewerPicker(selection: $compositionOption)
                Spacer()
            }
            .padding(.top)
            
            ZStack {
                ForEach(circleSegments.reversed(), id: \.self) { segment in
                    Circle()
                        .trim(from: 0, to: segment.fraction)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: 40)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: 192, height: 192)
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
            .onAppear {
                computeFractions()
            }
            .onChange(of: compositionOption) { _ in
                withAnimation {
                    computeFractions()
                }
            }
            
            Divider()
            ScrollView {
                VStack {
                    ForEach(listSegments.indices, id: \.self) { sectionIndex in
                        ForEach(listSegments[sectionIndex], id: \.self) { item in
                            FileCompositionItemRow(
                                itemName: item.name,
                                itemColor: item.color,
                                itemCount: item.count,
                                fraction: item.fraction
                            )
                        }
                        if sectionIndex != listSegments.indices.last {
                            Divider()
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 400)
            
            Divider()
            FileAtomTotalsRow()
                .padding(.vertical, 8)
        }
        .frame(minWidth: 350)
    }
    
    // MARK: - Fractions
    
    func computeFractions() {
        guard let file = proteinViewModel.dataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
        
        var newSegments = [InfoCapsuleSegment]()
        var newListSections = [[CompositionItem]]()
        
        switch compositionOption {
        case .element:
            
            elementComposition = ProteinElementComposition()
            for protein in proteins {
                elementComposition += protein.elementComposition
            }
            let totalAtoms = elementComposition.totalCount
            
            var importantTotal: Double = 0.0
            var importantElementItems = [CompositionItem]()
            for element in AtomElement.importantElements {
                let elementCount = elementComposition.elementCounts[element] ?? 0
                let elementFraction = Double(elementCount) / Double(totalAtoms)
                let elementColor = proteinViewModel.elementColors[Int(element.rawValue)]
                newSegments.append(InfoCapsuleSegment(
                    fraction: elementFraction + importantTotal,
                    color: elementColor
                ))
                importantElementItems.append(CompositionItem(
                    name: element.longName,
                    color: elementColor,
                    count: elementCount,
                    fraction: Double(elementCount) / Double(totalAtoms)
                ))
                importantTotal += elementFraction
            }
            newSegments.append(InfoCapsuleSegment(
                fraction: 1.0,
                color: proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
            ))
            newListSections.append(importantElementItems)
            
            var otherElementItems = [CompositionItem]()
            for element in AtomElement.otherElements {
                let elementCount = elementComposition.elementCounts[element] ?? 0
                let elementColor = proteinViewModel.elementColors[Int(element.rawValue)]
                otherElementItems.append(CompositionItem(
                    name: element.longName,
                    color: elementColor,
                    count: elementCount,
                    fraction: Double(elementCount) / Double(totalAtoms)
                ))
            }
            newListSections.append(otherElementItems)
        case .residue:
            residueComposition = ProteinResidueComposition()
            for proteinResidues in proteins.compactMap({ $0.residueComposition }) {
                residueComposition += proteinResidues
            }
            let totalAtoms = residueComposition.totalCount
            
            var currentTotal: Double = 0.0
            for residueKind in Residue.ResidueKind.allCases {
                var residueSegments = [CompositionItem]()
                for residue in Residue.allCases.filter({ $0.kind == residueKind }) {
                    let residueCount = residueComposition.residueCounts[residue] ?? 0
                    let residueFraction = Double(residueCount) / Double(totalAtoms)
                    let residueColor = proteinViewModel.residueColors[Int(residue.rawValue)]
                    newSegments.append(InfoCapsuleSegment(
                        fraction: residueFraction + currentTotal,
                        color: residueColor
                    ))
                    residueSegments.append(CompositionItem(
                        name: residue.name,
                        color: residueColor,
                        count: residueCount,
                        fraction: residueFraction
                    ))
                    currentTotal += residueFraction
                }
                if residueSegments.contains(where: {$0.count != 0}) {
                    newListSections.append(residueSegments)
                }
            }
        }
        
        self.circleSegments = newSegments
        self.listSegments = newListSections
    }
}

// MARK: - Previews

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        FileCompositionView()
    }
}
