//
//  AppearanceSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct AppearanceSegmentProtein: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var colorViewModel: ProteinColorViewModel
    @EnvironmentObject var visualizationViewModel: ProteinVisualizationViewModel
            
    // MARK: - View
    
    var body: some View {
        List {
            
            // MARK: - General section
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("General", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4)
            ) {

                ColorPickerRow(
                    title: NSLocalizedString("Background color", comment: ""),
                    selectedColor: $colorViewModel.backgroundColor
                )
            }
            #if targetEnvironment(macCatalyst)
            .listRowInsets(EdgeInsets(top: .zero, leading: 12, bottom: .zero, trailing: 12))
            #endif
            
            // MARK: - Visualization section
            
            VisualizationSection()
            
            // MARK: - Color section
            
            ColorSection()
            
            // MARK: - Shadows section
            
            ShadowsSection()
            
            // MARK: - Camera section
            Section(header: Text(NSLocalizedString("Focal distance", comment: ""))
                        .padding(.bottom, 4)
            ) {
                FocalLengthRow(focalLength: $visualizationViewModel.cameraFocalLength)
            }

        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(DefaultListStyle())
    }
}

// MARK: - SwiftUI Previews
struct AppearanceSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSegmentProtein()
            .previewDevice("iPhone SE (2nd generation)")
            .previewLayout(.sizeThatFits)
    }
}
