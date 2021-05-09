//
//  ProeteinSequenceView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

struct ProteinSequenceView: View {
    var body: some View {
        ZStack {
            Color.red
            HStack {

            }
        }
        .frame(height: 36)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.opaqueSeparator), lineWidth: 3)
        )
    }
}

struct ProeteinSequenceView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSequenceView()
            .previewDevice("iPhone SE (2nd generation)")
    }
}
