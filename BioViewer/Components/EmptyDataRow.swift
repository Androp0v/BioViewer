//
//  EmptyDataRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/12/21.
//

import SwiftUI

struct EmptyDataRow: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .italic()
    }
}

struct EmptyDataRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EmptyDataRow(text: NSLocalizedString("No data", comment: ""))
        }
    }
}
