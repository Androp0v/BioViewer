//
//  WhatsNewView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

struct WhatsNewView: View {
    
    @Environment(\.dismiss) var dismiss
    let version = "1.3"
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
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
                .navigationTitle(NSLocalizedString("What's new (\(version))", comment: ""))
                
                // Bottom buttons
                VStack {
                    Divider()
                    
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text(NSLocalizedString("Continue", comment: ""))
                            .padding(4)
                            .frame(maxWidth: .infinity)
                    })
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text(NSLocalizedString("Don't notify new features", comment: ""))
                            .padding(4)
                            .frame(maxWidth: .infinity)
                    })
                        .padding(.bottom, 4)
                }
                .background(.regularMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView()
    }
}
