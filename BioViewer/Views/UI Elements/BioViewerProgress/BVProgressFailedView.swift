//
//  BVProgressFailedView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/11/23.
//

import SwiftUI

struct BVProgressFailedView: View {
    var body: some View {
        Image(systemName: "exclamationmark.octagon")
            .resizable()
            .padding(16)
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    BVProgressFailedView()
}
