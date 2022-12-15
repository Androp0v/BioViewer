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
    
    var body: some View {
        Section(
            header: Text(NSLocalizedString("Color", comment: ""))
                    .padding(.bottom, 4),
            content: {
                PersistentDisclosureGroup(
                    for: .colorGroup,
                    defaultOpen: true,
                    content: {
                        // MARK: - Color by element
                        if proteinViewModel.colorBy == ProteinColorByOption.element {
                            // TO-DO: Make color palette work
                            /*
                            ColorPaletteRow(colorPalette: ColorPalette(.default))
                            */
                            
                            ColorPickerRow(
                                title: NSLocalizedString("C atom color", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.CARBON)]
                            )
                            ColorPickerRow(
                                title: NSLocalizedString("H atom color", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.HYDROGEN)]
                            )
                            ColorPickerRow(
                                title: NSLocalizedString("N atom color", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.NITROGEN)]
                            )
                            ColorPickerRow(
                                title: NSLocalizedString("O atom color", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.OXYGEN)]
                            )
                            ColorPickerRow(
                                title: NSLocalizedString("S atom color", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.SULFUR)]
                            )
                            ColorPickerRow(
                                title: NSLocalizedString("Other atoms", comment: ""),
                                selectedColor: $proteinViewModel.elementColors[Int(AtomType.UNKNOWN)]
                            )
                        } else {
                            if let subunits = proteinViewModel.dataSource.getFirstProtein()?.subunits {
                                // MARK: - Color by subunit
                                ForEach(subunits, id: \.id) { subunit in
                                    // TO-DO: Show real subunit list
                                    ColorPickerRow(
                                        title: NSLocalizedString("Subunit \(subunit.getUppercaseName())", comment: ""),
                                        selectedColor: $proteinViewModel.subunitColors[subunit.id]
                                    )
                                }
                            } else {
                                EmptyDataRow(text: NSLocalizedString("No subunits found", comment: ""))
                                    .padding(.vertical, 2)
                            }
                        }
                    },
                    label: {
                        // TO-DO: Refactor pickerOptions to get them from ProteinColorByOption
                        PickerRow(
                            optionName: "Color by",
                            selectedOption: $proteinViewModel.colorBy,
                            pickerOptions:
                                [
                                    "Element",
                                    "Subunit"
                                ]
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
