//
//  CustomLinearProgressView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/10/21.
//

import SwiftUI

struct CustomLinearProgressView: View {
    
    var value: Float?
    var total: Float
    
    var body: some View {
        if let value = value {
            GeometryReader { geometry in
                ZStack {
                    Color.secondarySystemBackground
                    HStack {
                        Color.accentColor
                            .frame(width: geometry.size.width * CGFloat(value) / CGFloat(total))
                        Spacer()
                    }
                }
            }
            .ignoresSafeArea()
            .frame(height: 2)
        } else {
            EmptyView()
        }
    }
}

struct MacLinearProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CustomLinearProgressView(value: 0.2, total: 1.0)
    }
}
