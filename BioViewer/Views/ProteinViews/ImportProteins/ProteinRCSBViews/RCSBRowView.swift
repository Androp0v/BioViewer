//
//  ProteinRCSBRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct RCSBRowView: View {
    
    var title: String?
    var description: String?
    var authors: String?
    var image: Image?
        
    @Binding var rcsbShowSheet: Bool
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var rcsbImportViewModel: RCSBImportViewModel
    
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
        .onTapGesture {
            Task {
                guard let rcsbid = title else { return }
                try await rcsbImportViewModel.fetchPDBFile(rcsbid: rcsbid, proteinViewModel: proteinViewModel)
            }
            rcsbShowSheet = false
        }
    }
}

struct RCSBRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            RCSBRowView(title: "2OGM",
                        description: "The crystal structure of the large ribosomal subunit from Deinococcus radiodurans complexed with the pleuromutilin derivative SB-571519",
                        authors: "Davidovich, C., Bashan, A., Auerbach-Nevo, T., Yonath, A.",
                        image: nil,
                        rcsbShowSheet: .constant(true))
        }
    }
}
