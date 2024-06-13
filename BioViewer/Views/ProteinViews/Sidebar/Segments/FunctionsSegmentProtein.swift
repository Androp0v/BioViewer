//
//  FunctionsSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 3/12/21.
//

import SwiftUI

struct FunctionsSegmentProtein: View {
    
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("Protein properties", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4),
                    content: {
                ComputedPropertyRow(propertyName: "volume",
                                    units: "Å^{3}",
                                    value: .constant(8842.4),
                                    errorInterval: .constant(26.1))
            })
                .disabled(proteinDataSource.proteinCount == 0)
            
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        #if os(iOS)
        .listStyle(GroupedListStyle())
        #endif
    }
}

struct FunctionsSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FunctionsSegmentProtein()
            .environmentObject(ProteinViewModel())
    }
}
