//
//  PeriodicTableContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/22.
//

import SwiftUI

struct PeriodicTableContentView: View {
    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView(.horizontal) {
                VStack(spacing: 2) {
                    ForEach(0..<6) { _ in
                        HStack(spacing: 2) {
                            ForEach(0..<17, id: \.self) { _ in
                                ZStack {
                                    Rectangle()
                                        .aspectRatio(1.0, contentMode: .fit)
                                    Text("He")
                                        .foregroundColor(.white)
                                }
                                .frame(minWidth: 24)
                            }
                        }
                    }
                }
                .padding()
                .frame(idealWidth: geometryProxy.size.width)
            }
        }
    }
}

struct PeriodicTableContentView_Previews: PreviewProvider {
    static var previews: some View {
        PeriodicTableContentView()
    }
}
