//
//  StatusView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import SwiftUI

public struct StatusViewConstants {
    #if targetEnvironment(macCatalyst)
    static let height: CGFloat = 24
    static let cornerRadius: CGFloat = 6
    #else
    static let height: CGFloat = 32
    static let cornerRadius: CGFloat = 8
    #endif
}

struct StatusView: View {

    @ObservedObject var statusViewModel: StatusViewModel

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            HStack (spacing: 8) {
                if statusViewModel.statusRunning {
                    ProgressView()
                }
                Text("\(statusViewModel.statusText)")
            }
            .padding(.horizontal, 8)
            if statusViewModel.statusRunning {
                VStack(spacing: 0) {
                    Spacer()
                    ProgressView(value: statusViewModel.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        }
        .frame(height: StatusViewConstants.height)
        .cornerRadius(StatusViewConstants.cornerRadius)
    }

}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView(statusViewModel: StatusViewModel())
            .frame(width: 300, height: 32)
            .environmentObject(ProteinViewModel())
    }
}
