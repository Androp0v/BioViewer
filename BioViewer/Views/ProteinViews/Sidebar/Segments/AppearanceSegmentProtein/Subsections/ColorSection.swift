//
//  ColorSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/6/22.
//

import BioViewerFoundation
import SwiftUI

struct ColorSection: View {
    
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    @Environment(ProteinVisualizationViewModel.self) var visualizationViewModel: ProteinVisualizationViewModel
    
    @State var presentPeriodicTable: Bool = false
    @State var showMoreElements: Bool = false
    
    var body: some View {
        @Bindable var colorViewModel = colorViewModel
        Section(
            header: Text(NSLocalizedString("Color", comment: ""))
                    .padding(.bottom, 4),
            content: {
                if visualizationViewModel.visualization == .ballAndStick {
                    ColorPickerRow(
                        title: NSLocalizedString("Bond color", comment: ""),
                        selectedColor: $colorViewModel.bondColor
                    )
                }
                PersistentDisclosureGroup(
                    for: .colorGroup,
                    defaultOpen: true,
                    content: {
                        
                        switch colorViewModel.colorBy {
                        
                        // MARK: - Color by element
                        case .element:
                            // TO-DO: Make color palette work
                            /*
                            ColorPaletteRow(colorPalette: ColorPalette(.default))
                            */
                            
                            ForEach(AtomElement.importantElements, id: \.self) { element in
                                ColorPickerRow(
                                    title: NSLocalizedString("\(element.name) atom color", comment: ""),
                                    selectedColor: $colorViewModel.elementColors[Int(element.rawValue)]
                                )
                            }
                            
                            if showMoreElements {
                                ForEach(AtomElement.otherElements, id: \.self) { element in
                                    ColorPickerRow(
                                        title: NSLocalizedString("\(element.name) atom color", comment: ""),
                                        selectedColor: $colorViewModel.elementColors[Int(element.rawValue)]
                                    )
                                }
                            }
                            
                            ColorPickerRow(
                                title: NSLocalizedString("Other atoms", comment: ""),
                                selectedColor: $colorViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
                            )
                            
                            ButtonRow(
                                action: {
                                    withAnimation {
                                        showMoreElements.toggle()
                                    }
                                },
                                text: NSLocalizedString(
                                    showMoreElements
                                        ? NSLocalizedString("Show less", comment: "")
                                        : NSLocalizedString("Show more", comment: ""),
                                    comment: ""
                                )
                            )
                            
                        // MARK: - Color by chain
                        case .chain:
                            if let chains = proteinDataSource.getFirstProtein()?.chainComposition?.uniqueChainIDs {
                                ForEach(chains, id: \.self) { chain in
                                    // TO-DO: Show real subunit list
                                    ColorPickerRow(
                                        title: "\(chain.displayName)",
                                        selectedColor: $colorViewModel.chainColors[Int(chain.rawValue)]
                                    )
                                }
                            } else {
                                EmptyDataRow(text: NSLocalizedString("No subunits found", comment: ""))
                                    .padding(.vertical, 2)
                            }
                        case .residue:
                            
                            // MARK: - Color by residue
                            
                            ForEach(Residue.ResidueKind.allCases.filter { $0 != .unknown }, id: \.self) { residueKind in
                                PersistentDisclosureGroup(
                                    for: {
                                        switch residueKind {
                                        case .aminoAcid:
                                            return .residueColoringAminoAcid
                                        case .dnaNucleobase:
                                            return .residueColoringDNANucleobase
                                        case .rnaNucleobase:
                                            return .residueColoringRNANucleobase
                                        case .unknown:
                                            return .error
                                        }
                                    }(),
                                    defaultOpen: false,
                                    content: {
                                        let aminoAcids = Residue.allCases.filter({ $0.kind == residueKind })
                                        ForEach(aminoAcids, id: \.rawValue) { residue in
                                            ColorPickerRow(
                                                title: residue.name,
                                                selectedColor: $colorViewModel.residueColors[Int(residue.rawValue)]
                                            )
                                        }
                                    },
                                    label: {
                                        Text(NSLocalizedString(residueKind.name, comment: ""))
                                            #if targetEnvironment(macCatalyst)
                                            .padding(.leading, 8)
                                            #else
                                            .padding(.trailing, 16)
                                            #endif
                                    }
                                )
                            }
                            
                            ColorPickerRow(
                                title: Residue.unknown.name,
                                selectedColor: $colorViewModel.residueColors[Int(Residue.unknown.rawValue)]
                            )
                        case .secondaryStructure:
                            ForEach(SecondaryStructure.allCases, id: \.self) { structure in
                                ColorPickerRow(
                                    title: structure.name,
                                    selectedColor: $colorViewModel.structureColors[Int(structure.rawValue)]
                                )
                            }
                        }
                    },
                    label: {
                        PickerRow(
                            optionName: "Color by",
                            selection: $colorViewModel.colorBy
                        )
                        #if targetEnvironment(macCatalyst)
                        .padding(.leading, 8)
                        #else
                        .padding(.trailing, 16)
                        #endif
                    }
                )
                // TODO: Change color defaults
                /*
                if colorViewModel.colorBy == ProteinColorByOption.element {
                    ButtonRow(
                        action: {
                            withAnimation {
                                presentPeriodicTable.toggle()
                            }
                        },
                        text: NSLocalizedString("Configure defaults...", comment: "")
                    )
                    .sheet(
                        isPresented: $presentPeriodicTable,
                        content: {
                            PeriodicTableView()
                        }
                    )
                }
                 */
            }
        )
        #if targetEnvironment(macCatalyst)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 8)
        #endif
    }
}

struct ColorSection_Previews: PreviewProvider {
    static var previews: some View {
        ColorSection()
    }
}
