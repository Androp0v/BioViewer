//
//  SequenceRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/5/21.
//

import SwiftUI

struct SequenceRow: View {

    @State var sequence: [Character] = Array("MDSKGSSQKGSRLLLLLVVSNLLLCQGVVSTPVCPNGPGNCQVSLRDLFDRAVMVSHYIHDLSSEMFNEFDKRYAQGKGFITMALNSCHTSSLPTPEDKEQAQQTHHEVLMSLIL")

    var body: some View {
        LazyHStack(alignment: .top, spacing: 8) {
            ForEach(0..<sequence.count, id: \.self) {
                Text(String(sequence[$0]))
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .padding(.horizontal, 24)
    }
}

struct SequenceRow_Previews: PreviewProvider {
    static var previews: some View {
        SequenceRow()
    }
}
