//
//  PhotoModeFooter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeFooter: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                // TO-DO: Error handling
                try? proteinViewModel.renderer.drawHighQualityFrame(size: CGSize(width: 2048, height: 2048),
                                                                    photoModeViewModel: photoModeViewModel)
            }, label: {
                HStack {
                    Image(systemName: "camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text(NSLocalizedString("Take photo", comment: ""))
                        .bold()
                }
                .padding(4)
                .frame(maxWidth: .infinity)
            })
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
        }
        .background(.regularMaterial)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct PhotoModeFooter_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeFooter()
    }
}
