//
//  PhotoModeView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 12)
                PhotoModeHeader()
                Spacer()
                Divider()
                    .padding(.horizontal)
                Button(action: {
                    
                }, label: {
                    HStack {
                        Image(systemName: "camera")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                        Text(NSLocalizedString("Take photo", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                })
                    .buttonStyle(BorderedProminentButtonStyle())
                    .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button(action: {
                    dismiss()
                }, label: {
                    Text(NSLocalizedString("Cancel", comment: ""))
                })
            )
        }
    }
}

struct PhotoModeView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeView()
    }
}
