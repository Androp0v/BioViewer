//
//  SequenceRow.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 8/5/21.
//

import SwiftUI

struct SequenceRow: View {

    @State var sequence: [Character] = ["A","A","C","G","T","T","C","G","A","C","G","T","G","A"]

    var body: some View {
        VStack {
            Spacer()
            LazyHStack(alignment: .top, spacing: 10) {
                ForEach(0..<sequence.count, id: \.self) {
                    Text(String(sequence[$0]))
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 24)
            Spacer()
        }
        .frame(height: 100)
    }

}

struct SequenceRow_Previews: PreviewProvider {
    static var previews: some View {
        SequenceRow()
    }
}
