//
//  FileCompositionView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import BioViewerFoundation
import SwiftUI

private enum CompositionOption: PickableEnum {
    case element
    case chain
    case residue
    
    var displayName: String {
        switch self {
        case .element: 
            return "Element"
        case .chain:
            return "Chain"
        case .residue: 
            return "Residue"
        }
    }
}

struct FileCompositionView: View {
    
    @Environment(ProteinDataSource.self) var proteinDataSource: ProteinDataSource
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    
    @State private var compositionOption: CompositionOption = .element
    @State private var compositionSegments = [CompositionItem]()
    
    @State private var elementComposition = ProteinElementComposition()
    @State private var chainComposition = ProteinChainComposition()
    @State private var residueComposition = ProteinResidueComposition()
    
    @State private var selectedSegmentID: CompositionItem.ID?
    
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
            
            FileCompositionChartView(
                segments: compositionSegments,
                selectedSegmentID: $selectedSegmentID
            )
            .frame(width: 256, height: 256)
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
            .onAppear {
                computeFractions()
            }
            .onChange(of: compositionOption) {
                withAnimation {
                    selectedSegmentID = nil
                    computeFractions()
                }
            }
            
            Divider()
            VStack(spacing: .zero) {
                Table(compositionSegments, selection: $selectedSegmentID) {
                    TableColumn("Composition") { item in
                        HStack {
                            Circle()
                                .stroke(
                                    Color.separator,
                                    style: StrokeStyle(lineWidth: 1)
                                )
                                .background {
                                    Circle().foregroundColor(item.color)
                                }
                                .frame(width: 8, height: 8)
                            Text(item.name)
                        }
                    }
                    .width(min: 150)
                    TableColumn("Count") { item in
                        Text("\(item.count)")
                    }
                    TableColumn("Fraction") { item in
                        Text(String(format: "%.2f", item.fraction * 100) + "%")
                    }
                }
            }
        }
        .frame(idealWidth: 350)
        .safeAreaInset(edge: .bottom) {
            if selectedSegmentID != nil {
                VStack(spacing: .zero) {
                    Divider()
                    Button(
                        action: {
                            withAnimation {
                                selectedSegmentID = nil
                            }
                        }, label: {
                            Label("Remove selection", systemImage: "xmark")
                                .padding(4)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                    #if targetEnvironment(macCatalyst)
                    .padding(.bottom, 8)
                    #endif
                }
                .background(.regularMaterial)
            }
        }
        .frame(idealHeight: 600)
    }
    
    // MARK: - Fractions
    
    func computeFractions() {
        guard let file = proteinDataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinDataSource.modelsForFile(file: file) else { return }
        
        var newSegments = [CompositionItem]()
        
        elementComposition = ProteinElementComposition()
        chainComposition = ProteinChainComposition()
        residueComposition = ProteinResidueComposition()
        for protein in proteins {
            elementComposition += protein.elementComposition
            chainComposition += protein.chainComposition ?? ProteinChainComposition()
            residueComposition += protein.residueComposition ?? ProteinResidueComposition()
        }
        let totalAtoms = elementComposition.totalCount
        
        switch compositionOption {
        case .element:
            for elementSection in [AtomElement.importantElements, AtomElement.otherElements] {
                for element in elementSection {
                    let elementCount = elementComposition.elementCounts[element] ?? 0
                    let elementColor = colorViewModel.elementColors[Int(element.rawValue)]
                    newSegments.append(CompositionItem(
                        name: element.longName,
                        color: elementColor,
                        count: elementCount,
                        fraction: Double(elementCount) / Double(totalAtoms)
                    ))
                }
            }
        case .chain:
            for chain in chainComposition.uniqueChainIDs {
                let chainCount = chainComposition.chainIDCounts[chain] ?? 0
                let chainColor = colorViewModel.chainColors[Int(chain.rawValue)]
                newSegments.append(CompositionItem(
                    name: chain.displayName,
                    color: chainColor,
                    count: chainCount,
                    fraction: Double(chainCount) / Double(totalAtoms)
                ))
            }
        case .residue:
            for residueKind in Residue.ResidueKind.allCases {
                for residue in Residue.allCases.filter({ $0.kind == residueKind }) {
                    let residueCount = residueComposition.residueCounts[residue] ?? 0
                    let residueColor = colorViewModel.residueColors[Int(residue.rawValue)]
                    newSegments.append(CompositionItem(
                        name: residue.name,
                        color: residueColor,
                        count: residueCount,
                        fraction: Double(residueCount) / Double(totalAtoms)
                    ))
                }
            }
        }
        self.compositionSegments = newSegments
    }
}

// MARK: - Previews

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        FileCompositionView()
    }
}
