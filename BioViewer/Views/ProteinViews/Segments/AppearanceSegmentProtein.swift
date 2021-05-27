//
//  AppearanceSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct AppearanceSegmentProtein: View {

    private enum ProteinVisualizationOption: Int {
        case none = 0
        case solidSpheres = 1
    }

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State private var selectedProteinVisualization: Int = ProteinVisualizationOption.solidSpheres.rawValue

    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text("General").padding(.top, 64)) {

                ColorPickerRow(title: "Background color",
                               selectedColor: $proteinViewModel.sceneDelegate.sceneBackground)

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

            }

            if selectedProteinVisualization == ProteinVisualizationOption.solidSpheres.rawValue {
                // TO-DO: Make picker actually change atom color
                Section(header: Text("Solid spheres"), content: {
                    ColorPickerRow(title: "C atom color",
                                   selectedColor: .constant(Color.green))
                    ColorPickerRow(title: "H atom color",
                                   selectedColor: .constant(Color.gray))
                    ColorPickerRow(title: "N atom color",
                                   selectedColor: .constant(Color.blue))
                    ColorPickerRow(title: "O atom color",
                                   selectedColor: .constant(Color.red))
                    ColorPickerRow(title: "S atom color",
                                   selectedColor: .constant(Color.orange))
                    ColorPickerRow(title: "Unknown atom color",
                                   selectedColor: .constant(Color.gray))
                })
            }

        }
        .listStyle(GroupedListStyle())
    }
}

struct AppearanceSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSegmentProtein()
            .previewDevice("iPhone SE (2nd generation)")
            .previewLayout(.sizeThatFits)
            .environmentObject(ProteinViewModel())
    }
}
