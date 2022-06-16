//
//  RCSBDetail.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/6/22.
//

import SwiftUI

struct RCSBDetailView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack(alignment: .leading) {
                Text("2OGM")
                    .font(.largeTitle)
                    .bold()
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(uiColor: .separator),
                                style: StrokeStyle(lineWidth: 2))
                        .opacity(0.2)
                }
                .aspectRatio(1.0, contentMode: .fit)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            VStack(spacing: .zero) {
                Divider()
                Button(action: {
                    // TO-DO
                }, label: {
                    HStack {
                        if #available(iOS 16.0, *) {
                            Image(systemName: "arrow.down.doc")
                                .bold()
                        }
                        Text(NSLocalizedString("Download", comment: ""))
                            .bold()
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                })
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .background(.regularMaterial)
        }
    }
}

struct RCSBDetail_Previews: PreviewProvider {
    static var previews: some View {
        RCSBDetailView()
    }
}
