//
//  PhotoModeUnsupportedView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/3/22.
//

import SwiftUI

struct PhotoModeUnsupportedView: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(NSLocalizedString(":(", comment: ""))
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Spacer()
                .frame(height: 24)
            Text(NSLocalizedString("Photo Mode is not supported on this device.", comment: ""))
                .font(.headline)
                .bold()
                .multilineTextAlignment(.center)
            Text(NSLocalizedString("Supported devices include iOS devices with A11 or later and Apple Silicon Macs.", comment: ""))
                .font(.body)
                .foregroundColor(.gray)
            Spacer()
            Button(action: {
                dismiss()
            }, label: {
                Text(NSLocalizedString("Close", comment: ""))
                    .bold()
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PhotoModeUnsupportedView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeUnsupportedView()
    }
}
