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
    case residue
    
    var displayName: String {
        switch self {
        case .element: return "Element"
        case .residue: return "Residue"
        }
    }
}

struct FileCompositionView: View {
    
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    
    @State private var compositionOption: CompositionOption = .element
    @State private var compositionSections = [[CompositionItem]]()
    @State private var elementComposition = ProteinElementComposition()
    @State private var residueComposition = ProteinResidueComposition()
    
    @State private var selectedSegment: CompositionItem?
    
    private enum AnimationConstants {
        static let duration: Double = 0.8
    }
        
    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                HStack(spacing: 8) {
                    Spacer()
                    Text(NSLocalizedString("Atoms of each", comment: ""))
                    BioViewerPicker(selection: $compositionOption)
                    Spacer()
                }
                .padding(.top)
                
                FileCompositionChartView(
                    segments: compositionSections.flatMap { $0 },
                    selectedSegment: $selectedSegment
                )
                .frame(width: 256, height: 256)
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
                .onAppear {
                    computeFractions()
                }
                .onChange(of: compositionOption) {
                    withAnimation {
                        selectedSegment = nil
                        computeFractions()
                    }
                }
                
                Divider()
                VStack(spacing: .zero) {
                    ForEach(compositionSections.indices, id: \.self) { sectionIndex in
                        ForEach(compositionSections[sectionIndex], id: \.self) { item in
                            Button(
                                action: {
                                    withAnimation {
                                        selectedSegment = item
                                    }
                                },
                                label: {
                                    FileCompositionItemRow(
                                        itemName: item.name,
                                        itemColor: item.color,
                                        itemCount: item.count,
                                        fraction: item.fraction
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(
                                        item == selectedSegment
                                        ? Color.accentColor.opacity(0.3)
                                        : Color.clear
                                    )
                                    .contentShape(Rectangle())
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 8)
                                }
                            )
                            .buttonStyle(.plain)
                            .disabled(item.count == 0)
                        }
                        if sectionIndex != compositionSections.indices.last {
                            Divider()
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                FileAtomTotalsRow()
                    .padding(.vertical, 8)
            }
            .frame(idealWidth: 450)
        }
        .safeAreaInset(edge: .bottom) {
            if selectedSegment != nil {
                VStack(spacing: .zero) {
                    Divider()
                    Button(
                        action: {
                            withAnimation {
                                selectedSegment = nil
                            }
                        }, label: {
                            Label("Remove selection", systemImage: "xmark")
                                .padding(8)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .padding(8)
                }
                .background(.regularMaterial)
            }
        }
    }
    
    // MARK: - Fractions
    
    func computeFractions() {
        guard let file = proteinDataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinDataSource.modelsForFile(file: file) else { return }
        
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
                    let elementColor = colorViewModel.elementColors[Int(element.rawValue)]
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
                    let residueColor = colorViewModel.residueColors[Int(residue.rawValue)]
                    residueSegments.append(CompositionItem(
                        name: residue.name,
                        color: residueColor,
                        count: residueCount,
                        fraction: Double(residueCount) / Double(totalAtoms)
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
