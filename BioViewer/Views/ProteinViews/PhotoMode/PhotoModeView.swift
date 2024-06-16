//
//  PhotoModeView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeView: View {
    
    let renderer: ProteinRenderer
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
                    PhotoModeFooter(renderer: renderer)
                        .environment(photoModeViewModel.shutterAnimator)
                        .environment(photoModeViewModel)
                }
            }
            .navigationTitle(NSLocalizedString("Photo Mode", comment: ""))
            #if os(iOS)
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
            #endif
        }
    }
}
