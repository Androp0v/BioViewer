//
//  ProteinRCSBRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct ProteinRCSBRowView: View {
    
    @Binding var title: String?
    @Binding var description: String?
    @Binding var image: Image?
    
    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                Color.white
                Image(systemName: "camera.metering.unknown")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96)
                image?
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 96)
            }
            .cornerRadius(12)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 96)
            .padding(.trailing, 8)
            
            VStack(alignment: .leading) {
                Text(title ?? "")
                    .font(.headline)
                Text(description ?? "")
            }
        }
    }
}

struct ProteinRCSBRowView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinRCSBRowView(title: .constant("2OGM"),
                           description: .constant("The crystal structure of the large ribosomal subunit from Deinococcus radiodurans complexed with the pleuromutilin derivative SB-571519"),
                           image: .constant(nil))
    }
}
