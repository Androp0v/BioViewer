//
//  NewsRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

struct NewsRow: View {
    
    let rowType: NewsRowType
    let title: String
    let subtitle: String
    
    init(whatsNewItem: WhatsNew) {
        self.rowType = whatsNewItem.type
        self.title = whatsNewItem.title
        self.subtitle = whatsNewItem.subtitle
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            switch rowType {
            case .feature:
                VStack(spacing: 4) {
                    Image(systemName: "newspaper.fill")
                        .foregroundColor(.accentColor)
                        .font(.title)
                    Text("New".uppercased())
                        .bold()
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 4)
            case .fix:
                VStack(spacing: 4) {
                    Image(systemName: "wrench.fill")
                        .foregroundColor(.accentColor)
                        .font(.title)
                    Text("Fix".uppercased())
                        .bold()
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 4)
            }
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                Text(subtitle)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
        .listRowSeparator(.hidden)
    }
}

struct NewsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            NewsRow(whatsNewItem: WhatsNew(type: .feature,
                                           title: "Selectable atom radii",
                                           subtitle: "Atom radii can now be selected for both the solid spheres and the ball and stick visualization modes."))
        }
        .listStyle(.plain)
    }
}
