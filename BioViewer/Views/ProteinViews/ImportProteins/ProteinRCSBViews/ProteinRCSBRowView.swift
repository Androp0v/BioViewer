//
//  ProteinRCSBRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct ProteinRCSBRowView: View {
    
    var title: String?
    var description: String?
    var authors: String?
    var image: Image?
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let imageCornerRadius: CGFloat = 4
        #else
        static let imageCornerRadius: CGFloat = 8
        #endif
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack {
                Color.white
                Image(systemName: "questionmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundColor(Color(uiColor: .opaqueSeparator))
                image?
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 96)
                RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
                    .stroke(Color(uiColor: .separator),
                            style: StrokeStyle(lineWidth: 2))
                    .opacity(0.2)
            }
            .cornerRadius(Constants.imageCornerRadius)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 96)
            .padding(8)
            
            VStack(alignment: .leading, spacing: 4) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                }
                if let description = description {
                    Text(description)
                }
                if let authors = authors {
                    Text(authors)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .italic()
                }
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets())
    }
}

struct ProteinRCSBRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProteinRCSBRowView(title: "2OGM",
                               description: "The crystal structure of the large ribosomal subunit from Deinococcus radiodurans complexed with the pleuromutilin derivative SB-571519",
                               authors: "Davidovich, C., Bashan, A., Auerbach-Nevo, T., Yonath, A.",
                               image: nil)
        }
    }
}
