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
                    ColorPaletteRow(indent: true,
                                    colorPalette: ColorPalette(.default))
                    if proteinViewModel.renderer.scene.colorBy == ProteinColorByOption.element {
                        ColorPickerRow(title: NSLocalizedString("C atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.cAtomColor,
                                       indent: true)
                        ColorPickerRow(title: NSLocalizedString("H atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.hAtomColor,
                                       indent: true)
                        ColorPickerRow(title: NSLocalizedString("N atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.nAtomColor,
                                       indent: true)
                        ColorPickerRow(title: NSLocalizedString("O atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.oAtomColor,
                                       indent: true)
                        ColorPickerRow(title: NSLocalizedString("S atom color", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.sAtomColor,
                                       indent: true)
                        ColorPickerRow(title: NSLocalizedString("Other atoms", comment: ""),
                                       selectedColor: $proteinViewModel.renderer.scene.unknownAtomColor,
                                       indent: true)
                    } else if let subunits = proteinViewModel.dataSource.files.first?.protein.subunits {
                        ForEach(subunits, id: \.id) { subunit in
                            // TO-DO: Show real subunit list
                            ColorPickerRow(title: NSLocalizedString("Subunit \(subunit.getUppercaseName())", comment: ""),
                                           selectedColor: $proteinViewModel.renderer.scene.subunitColors[subunit.id],
                                           indent: true)
                        }
                    }
                })
            }
            
            // MARK: - Shadows section
            Section(header: Text(NSLocalizedString("Shadows", comment: ""))
                        .padding(.bottom, 4)) {
                SwitchRow(title: NSLocalizedString("Cast shadows", comment: ""),
                          toggledVariable: $proteinViewModel.renderer.scene.hasShadows)
                SwitchRow(title: NSLocalizedString("Depth cueing", comment: ""),
                          toggledVariable: $proteinViewModel.renderer.scene.hasDepthCueing)
            }
            
            // MARK: - Camera section
            Section(header: Text(NSLocalizedString("Focal distance", comment: ""))
                        .padding(.bottom, 4)) {
                SliderRow(focalLength: $proteinViewModel.cameraFocalLength)
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
