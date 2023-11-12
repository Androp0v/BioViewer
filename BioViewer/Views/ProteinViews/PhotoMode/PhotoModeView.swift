//
//  PhotoModeView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeView: View {
    
    @Environment(\.dismiss) var dismiss
    @State var photoModeViewModel = PhotoModeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                PhotoModeContent()
                    .edgesIgnoringSafeArea(.bottom)
                    .environment(photoModeViewModel.shutterAnimator)
                    .environment(photoModeViewModel)
                
                VStack {
                    Spacer()
                    PhotoModeFooter()
                        .environment(photoModeViewModel.shutterAnimator)
                        .environment(photoModeViewModel)
                }
            }
            .navigationTitle(NSLocalizedString("Photo Mode", comment: ""))
            .navigationBarItems(leading:
                Button(
                    action: {
                        dismiss()
                    }, 
                    label: {
                        Text(NSLocalizedString("Cancel", comment: ""))
                    }
                )
                .disabled(photoModeViewModel.shutterAnimator.shutterAnimationRunning)
            )
        }
    }
}

struct PhotoModeView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeView()
    }
}
