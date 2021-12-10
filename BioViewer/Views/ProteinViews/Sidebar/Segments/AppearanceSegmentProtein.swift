//
//  AppearanceSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct AppearanceSegmentProtein: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    // MARK: - Picker properties
    
    @State private var selectedProteinVisualization: Int = ProteinVisualizationOption.solidSpheres
    
    private enum ProteinVisualizationOption {
        static let none: Int = 0
        static let solidSpheres: Int = 1
    }
    
    // MARK: - View
    
    var body: some View {
        List {
            
            // MARK: - General section
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("General", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4)) {

                ColorPickerRow(title: NSLocalizedString("Background color", comment: ""),
                               selectedColor: $proteinViewModel.backgroundColor)
                // TO-DO: Enable depth cueing
                /*
                SwitchRow(title: NSLocalizedString("Depth cueing", comment: ""),
                          toggledVariable: .constant(false))
                */

                // TO-DO:

                /*
                PickerRow(optionName: "View protein as",
                          selectedVisualization: $selectedProteinVisualization,
                          pickerOptions: ["None",
                                          "Space-filling spheres"])
                    .onChange(of: selectedProteinVisualization, perform: { value in
                        // TO-DO: This is only working as a binary switch, not a picker.
                        if value == ProteinVisualizationOption.none.rawValue {
                            proteinViewModel.sceneDelegate.showProtein = false
                        } else {
                            proteinViewModel.sceneDelegate.showProtein = true
                        }
                    })

                SwitchRow(title: "Show solvent-accessible surface", toggledVariable: $proteinViewModel.sceneDelegate.showSurface)
                */

            }
            
            // MARK: - Color section
            
            if selectedProteinVisualization == ProteinVisualizationOption.solidSpheres {
                Section(header: Text(NSLocalizedString("Color", comment: ""))
                            .padding(.bottom, 4), content: {
                    // TO-DO: Refactor pickerOptions to get them from ProteinColorByOption
                    PickerRow(optionName: "Color by",
                              selectedOption: $proteinViewModel.renderer.scene.colorBy,
                              pickerOptions: ["Element",
                                              "Subunit"])
                    // TO-DO: Make it work
                    ColorPaletteRow(colorPalette: ColorPalette(.default))
                        .indentRow()
                    if proteinViewModel.renderer.scene.colorBy == ProteinColorByOption.element {
                        ColorPickerRow(title: NSLocalizedString("C atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.cAtomColor)
                            .indentRow()
                        ColorPickerRow(title: NSLocalizedString("H atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.hAtomColor)
                            .indentRow()
                        ColorPickerRow(title: NSLocalizedString("N atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.nAtomColor)
                            .indentRow()
                        ColorPickerRow(title: NSLocalizedString("O atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.oAtomColor)
                            .indentRow()
                        ColorPickerRow(title: NSLocalizedString("S atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.sAtomColor)
                            .indentRow()
                        ColorPickerRow(title: NSLocalizedString("Other atoms", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.unknownAtomColor)
                            .indentRow()
                    } else if let subunits = proteinViewModel.dataSource.files.first?.protein.subunits {
                        ForEach(subunits, id: \.id) { subunit in
                            // TO-DO: Show real subunit list
                            ColorPickerRow(title: NSLocalizedString("Subunit \(subunit.getUppercaseName())", comment: ""),
                                           selectedColor: $proteinViewModel.renderer.scene.subunitColors[subunit.id])
                                .indentRow()
                        }
                    }
                })
            }
            
            // MARK: - Shadows section
            Section(header: Text(NSLocalizedString("Shadows", comment: ""))
                        .padding(.bottom, 4)) {
                if AppState.hasSamplerCompareSupport() {
                    SwitchRow(title: NSLocalizedString("Cast shadows", comment: ""),
                              toggledVariable: $proteinViewModel.renderer.scene.hasShadows)
                    if proteinViewModel.renderer.scene.hasShadows {
                        SliderRow(title: NSLocalizedString("Strength", comment: ""),
                                  value: $proteinViewModel.renderer.scene.shadowStrength,
                                  minValue: 0.0,
                                  maxValue: 1.0)
                            .indentRow()
                    }
                }
                SwitchRow(title: NSLocalizedString("Depth cueing", comment: ""),
                          toggledVariable: $proteinViewModel.renderer.scene.hasDepthCueing)
                if proteinViewModel.renderer.scene.hasDepthCueing {
                    RangeRow(title: "Range:")
                        .indentRow()
                    SliderRow(title: NSLocalizedString("Strength", comment: ""),
                              value: $proteinViewModel.renderer.scene.shadowStrength,
                              minValue: 0.0,
                              maxValue: 1.0)
                        .indentRow()
                }
            }
            
            // MARK: - Camera section
            Section(header: Text(NSLocalizedString("Focal distance", comment: ""))
                        .padding(.bottom, 4)) {
                FocalLengthRow(focalLength: $proteinViewModel.cameraFocalLength)
            }

        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(GroupedListStyle())
    }
}

// MARK: - SwiftUI Previews
struct AppearanceSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSegmentProtein()
            .previewDevice("iPhone SE (2nd generation)")
            .previewLayout(.sizeThatFits)
            .environmentObject(ProteinViewModel())
    }
}
