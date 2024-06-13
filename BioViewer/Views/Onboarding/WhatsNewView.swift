//
//  WhatsNewView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

struct WhatsNewView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = WhatsNewViewModel()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                List(viewModel.newItems) { newItem in
                    NewsRow(whatsNewItem: newItem)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .navigationTitle(NSLocalizedString("What's new (\(viewModel.version))", comment: ""))
                
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
                        AppState.shared.userDoesNotWantUpdates()
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView()
    }
}
