//
//  EmptyFileRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/12/21.
//

import SwiftUI

struct EmptyFileRow: View {
    var body: some View {
        Text(NSLocalizedString("No imported files", comment: ""))
            .foregroundColor(.secondary)
            .italic()
    }
}

struct EmptyFileRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EmptyFileRow()
        }
    }
}
