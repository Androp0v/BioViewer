//
//  LongTextRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/11/21.
//

import SwiftUI

struct LongTextRow: View {
    
    @State var title: String
    var longText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if longText != nil {
                Text(longText ?? "")
                    .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LongTextRow_Previews: PreviewProvider {
    static var previews: some View {
        LongTextRow(title: "Description", longText: "Long text example")
    }
}
