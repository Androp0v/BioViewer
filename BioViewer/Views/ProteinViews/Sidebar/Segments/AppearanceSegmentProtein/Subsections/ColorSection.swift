//
//  ColorSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/6/22.
//

import SwiftUI

struct ColorSection: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    @State var presentPeriodicTable: Bool = false
    @State var showMoreElements: Bool = false
    
    var body: some View {
        Section(
            header: Text(NSLocalizedString("Color", comment: ""))
                    .padding(.bottom, 4),
            content: {
                if proteinViewModel.visualization == .ballAndStick {
                    ColorPickerRow(
                        title: NSLocalizedString("Bond color", comment: ""),
                        selectedColor: $proteinViewModel.bondColor
                    )
                }
                PersistentDisclosureGroup(
                    for: .colorGroup,
                    defaultOpen: true,
                    content: {
                        
                        switch proteinViewModel.colorBy {
                        
                        // MARK: - Color by element
                        case .element:
                            // TO-DO: Make color palette work
                            /*
                            ColorPaletteRow(colorPalette: ColorPalette(.default))
                            */
                            
                            ForEach(AtomElement.importantElements, id: \.self) { element in
                                ColorPickerRow(
                                    title: NSLocalizedString("\(element.name) atom color", comment: ""),
                                    selectedColor: $proteinViewModel.elementColors[Int(element.rawValue)]
                                )
                            }
                            
                            if showMoreElements {
                                ForEach(AtomElement.otherElements, id: \.self) { element in
                                    ColorPickerRow(
                                        title: NSLocalizedString("\(element.name) atom color", comment: ""),
                                        selectedColor: $proteinViewModel.elementColors[Int(element.rawValue)]
                                    )
                                }
                            }
                            
                            ColorPickerRow(
                                title: NSLocalizedString("Other atoms", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
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
                            
                        // MARK: - Color by subunit
                        case .subunit:
                            if let subunits = proteinViewModel.dataSource.getFirstProtein()?.subunits {
                                ForEach(subunits, id: \.id) { subunit in
                                    // TO-DO: Show real subunit list
                                    ColorPickerRow(
                                        title: NSLocalizedString("\(subunit.subunitName)", comment: ""),
                                        selectedColor: $proteinViewModel.subunitColors[subunit.id]
                                    )
                                }
                            } else {
                                EmptyDataRow(text: NSLocalizedString("No subunits found", comment: ""))
                                    .padding(.vertical, 2)
                            }
                        case .residue:
                            
                            // MARK: - Color by residue
                            
                            PersistentDisclosureGroup(
                                for: .residueColoringAminoAcid,
                                defaultOpen: false,
                                content: {
                                    let aminoAcids = Residue.allCases.filter({ $0.kind == .aminoAcid})
                                    ForEach(aminoAcids, id: \.rawValue) { residue in
                                        ColorPickerRow(
                                            title: residue.name,
                                            selectedColor: $proteinViewModel.residueColors[Int(residue.rawValue)]
                                        )
                                    }
                                },
                                label: {
                                    Text(NSLocalizedString("Amino acids", comment: ""))
                                        #if targetEnvironment(macCatalyst)
                                        .padding(.leading, 8)
                                        #else
                                        .padding(.trailing, 16)
                                        #endif
                                }
                            )
                            
                            PersistentDisclosureGroup(
                                for: .residueColoringDNANucleobase,
                                defaultOpen: false,
                                content: {
                                    let aminoAcids = Residue.allCases.filter({ $0.kind == .dnaNucleobase})
                                    ForEach(aminoAcids, id: \.rawValue) { residue in
                                        ColorPickerRow(
                                            title: residue.name,
                                            selectedColor: $proteinViewModel.residueColors[Int(residue.rawValue)]
                                        )
                                    }
                                },
                                label: {
                                    Text(NSLocalizedString("Deoxyribonucleotides", comment: ""))
                                        #if targetEnvironment(macCatalyst)
                                        .padding(.leading, 8)
                                        #else
                                        .padding(.trailing, 16)
                                        #endif
                                }
                            )
                            
                            PersistentDisclosureGroup(
                                for: .residueColoringRNANucleobase,
                                defaultOpen: false,
                                content: {
                                    let aminoAcids = Residue.allCases.filter({ $0.kind == .rnaNucleobase})
                                    ForEach(aminoAcids, id: \.rawValue) { residue in
                                        ColorPickerRow(
                                            title: residue.name,
                                            selectedColor: $proteinViewModel.residueColors[Int(residue.rawValue)]
                                        )
                                    }
                                },
                                label: {
                                    Text(NSLocalizedString("Ribonucleotides", comment: ""))
                                        #if targetEnvironment(macCatalyst)
                                        .padding(.leading, 8)
                                        #else
                                        .padding(.trailing, 16)
                                        #endif
                                }
                            )
                            
                            ColorPickerRow(
                                title: Residue.unknown.name,
                                selectedColor: $proteinViewModel.residueColors[Int(Residue.unknown.rawValue)]
                            )
                        }
                    },
                    label: {
                        // TO-DO: Refactor pickerOptions to get them from ProteinColorByOption
                        PickerRow(
                            optionName: "Color by",
                            selection: $proteinViewModel.colorBy
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
                if proteinViewModel.colorBy == ProteinColorByOption.element {
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
