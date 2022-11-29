//
//  InfoTextRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/11/21.
//

import SwiftUI

struct InfoTextRow: View {
    @State var text: String
    var value: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
            Text(value ?? "-")
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

struct InfoTextRow_Previews: PreviewProvider {
    static var previews: some View {
        InfoTextRow(text: "Number of something:", value: "3340")
    }
}
