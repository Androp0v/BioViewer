//
//  RCSBEmptyView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 1/12/21.
//

import SwiftUI

struct RCSBEmptyImportView: View {
    
    @Binding var rcsbShowSheet: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "text.magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            Spacer()
                .frame(height: 16)
            Text("Search protein structures by entering their RCSB ID.")
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            Spacer()
                .frame(height: 16)
            Text("Don't know what to search for?")
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            NavigationLink(destination: RCSBSuggestionsView(rcsbShowSheet: $rcsbShowSheet)) {
                Text("Here are some suggestions...")
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RCSBEmptyImportView_Previews: PreviewProvider {
    static var previews: some View {
        RCSBEmptyImportView(rcsbShowSheet: .constant(true))
    }
}
