//
//  InfoLongTextRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/11/21.
//

import SwiftUI

struct InfoLongTextRow: View {
    
    @State var title: String
    var longText: String?
    
    var body: some View {
        if let longText = longText {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(longText)
                    .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 4) {
                Text(title)
                    .multilineTextAlignment(.leading)
                    .frame(alignment: .leading)
                Text("-")
                    .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct LongTextRow_Previews: PreviewProvider {
    static var previews: some View {
        InfoLongTextRow(title: "Description", longText: "Long text example")
    }
}
