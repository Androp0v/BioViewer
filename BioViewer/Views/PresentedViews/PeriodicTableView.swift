//
//  PeriodicTableView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/22.
//

import SwiftUI

struct PeriodicTableView: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack {
                VStack {
                    Divider()
                    PeriodicTableContentView()
                    Spacer()
                }
                .navigationTitle("Elements")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(
                        action: {
                            dismiss()
                        },
                        label: {
                            Text(NSLocalizedString("Close", comment: ""))
                        }
                    )
                )
            }
        } else {
            EmptyView()
        }
    }
}

struct PeriodicTableView_Previews: PreviewProvider {
    static var previews: some View {
        PeriodicTableView()
    }
}
