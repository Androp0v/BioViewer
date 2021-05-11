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
            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
            ScrollView (.horizontal) {
                HStack {
                    Text("MDSKGSSQKGSRLLLLLVVSNLLLCQGVVSTPVCPNGPGNCQVSLRDLFDRAVMVSHYIHDLSS")
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 36+8)
                }
            }
            HStack {
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .regular))
                        .frame(width: 36)
                    Text("5'")
                        .foregroundColor(.white)
                }
                Spacer()
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .regular))
                        .frame(width: 36)
                    Text("3'")
                        .foregroundColor(.white)
                }
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

struct ProteinSequenceView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSequenceView()
            .previewDevice("iPhone SE (2nd generation)")
    }
}
