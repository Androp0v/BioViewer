//
//  FocalLengthRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/10/21.
//

import SwiftUI

struct FocalLengthRow: View {
    
    @Binding var focalLength: Float
    
    var body: some View {
        VStack(spacing: 0) {
            
            Slider(value: $focalLength, in: 24...300)
            
            HStack {
                Text("24")
                    .font(.system(size: 12))
                
                Spacer()
                
                Text("\(focalLength, specifier: "%.0f") mm")
                    .font(.system(size: 14))
                    .padding(.all, 4)
                    .foregroundColor(.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                Spacer()
                
                Text("300")
                    .font(.system(size: 12))
            }
        }
    }
}

struct FocalLengthRow_Previews: PreviewProvider {
    static var previews: some View {
        FocalLengthRow(focalLength: .constant(200))
    }
}
