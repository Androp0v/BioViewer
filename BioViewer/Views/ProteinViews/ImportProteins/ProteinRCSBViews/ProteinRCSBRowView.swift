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
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "gear")
                .resizable()
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
                           description: .constant("The crystal structure of the large ribosomal subunit from Deinococcus radiodurans complexed with the pleuromutilin derivative SB-571519"))
    }
}
