//
//  NewsRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

enum NewsRowType {
    case feature
    case fix
}

struct NewsRow: View {
    
    let rowType: NewsRowType
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 18) {
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
            }
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                Text(subtitle)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .listRowSeparator(.hidden)
    }
}

struct NewsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            NewsRow(rowType: .feature,
                    title: "Selectable atom radii",
                    subtitle: "Atom radii can now be selected for both the solid spheres and the ball and stick visualization modes.")
            NewsRow(rowType: .feature,
                    title: "Selectable atom radii",
                    subtitle: "Atom radii can now be selected for both the solid spheres and the ball and stick visualization modes.")
            NewsRow(rowType: .fix,
                    title: "Selectable atom radii",
                    subtitle: "Atom radii can now be selected for both the solid spheres and the ball and stick visualization modes.")
        }
        .listStyle(.plain)
    }
}
