//
//  PhotoModeView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var photoModeViewModel = PhotoModeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                PhotoModeContent()
                    .edgesIgnoringSafeArea(.bottom)
                    .environmentObject(photoModeViewModel)
                
                VStack {
                    Spacer()
                    PhotoModeFooter()
                        .environmentObject(photoModeViewModel)
                }
            }
            .navigationTitle(NSLocalizedString("Photo Mode", comment: ""))
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
