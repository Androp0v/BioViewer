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

struct FileCompositionView: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    @State private var compositionOption: CompositionOption = .element
    @State private var compositionSections = [[CompositionItem]]()
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
            
            FileCompositionCircleView(items: compositionSections)
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
                    ForEach(compositionSections.indices, id: \.self) { sectionIndex in
                        ForEach(compositionSections[sectionIndex], id: \.self) { item in
                            FileCompositionItemRow(
                                itemName: item.name,
                                itemColor: item.color,
                                itemCount: item.count,
                                fraction: item.fraction
                            )
                        }
                        if sectionIndex != compositionSections.indices.last {
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
        .frame(idealWidth: 450)
    }
    
    // MARK: - Fractions
    
    func computeFractions() {
        guard let file = proteinViewModel.dataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
        
        var newListSections = [[CompositionItem]]()
        
        elementComposition = ProteinElementComposition()
        residueComposition = ProteinResidueComposition()
        for protein in proteins {
            elementComposition += protein.elementComposition
            residueComposition += protein.residueComposition ?? ProteinResidueComposition()
        }
        let totalAtoms = elementComposition.totalCount
        
        switch compositionOption {
        case .element:
            for elementSection in [AtomElement.importantElements, AtomElement.otherElements] {
                var elementItems = [CompositionItem]()
                for element in elementSection {
                    let elementCount = elementComposition.elementCounts[element] ?? 0
                    let elementFraction = Double(elementCount) / Double(totalAtoms)
                    let elementColor = proteinViewModel.elementColors[Int(element.rawValue)]
                    elementItems.append(CompositionItem(
                        name: element.longName,
                        color: elementColor,
                        count: elementCount,
                        fraction: Double(elementCount) / Double(totalAtoms)
                    ))
                }
                newListSections.append(elementItems)
            }
        case .residue:
            for residueKind in Residue.ResidueKind.allCases {
                var residueSegments = [CompositionItem]()
                for residue in Residue.allCases.filter({ $0.kind == residueKind }) {
                    let residueCount = residueComposition.residueCounts[residue] ?? 0
                    let residueFraction = Double(residueCount) / Double(totalAtoms)
                    let residueColor = proteinViewModel.residueColors[Int(residue.rawValue)]
                    residueSegments.append(CompositionItem(
                        name: residue.name,
                        color: residueColor,
                        count: residueCount,
                        fraction: residueFraction
                    ))
                }
                if residueSegments.contains(where: {$0.count != 0}) {
                    newListSections.append(residueSegments)
                }
            }
        }
        self.compositionSections = newListSections
    }
}

// MARK: - Previews

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        FileCompositionView()
    }
}
