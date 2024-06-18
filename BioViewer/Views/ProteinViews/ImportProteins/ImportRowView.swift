//
//  ImportRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import SwiftUI

struct ImportRowView: View {
    var title: String
    var imageName: String
    var action: ProteinImportView.ImportAction
    var parent: ProteinImportView

    var body: some View {
        Button(
            action: {
                parent.launchImportAction(action: action)
            },
            label: {
                #if os(iOS)
                HStack(spacing: 10) {
                    Image(systemName: imageName)
                        .frame(width: 32, height: 32, alignment: .center)
                    Text(title)
                        .frame(width: 200, alignment: .leading)
                }
                .font(.headline)
                .foregroundColor(.white)
                #elseif os(macOS)
                HStack(spacing: 10) {
                    Image(systemName: imageName)
                        .frame(alignment: .center)
                    Text(title)
                        .frame(alignment: .leading)
                }
                #endif
            }
        )
    }
}
