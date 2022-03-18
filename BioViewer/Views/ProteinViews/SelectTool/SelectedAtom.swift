//
//  SelectedElement.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/2/22.
//

import SwiftUI

struct SelectedAtom: View {
    
    var element: String
    var elementName: String
    var radius: Float
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .leading) {
                Text(NSLocalizedString("Selected element", comment: ""))
                    .bold()
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                
                Button(action: {
                    // TO-DO
                }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                })
                    .foregroundColor(.gray)
                    .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .frame(width: 64, height: 64)
                        .foregroundColor(Color(uiColor: UIColor.systemBackground))
                    Rectangle()
                        .strokeBorder(Color.black, lineWidth: 2)
                        .frame(width: 64, height: 64)
                    Text("K")
                        .font(.largeTitle)
                        .bold()
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("**Atomic mass:** 39.09 u")
                    Text("**Radius:** \(radius) Å")
                }
                
                Spacer()
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .frame(maxWidth: 300, alignment: .bottomLeading)
        .padding()
    }
}

struct SelectedElement_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
                .ignoresSafeArea()
            SelectedAtom(element: "K",
                         elementName: "Potassium",
                         radius: 2.80)
        }
    }
}
