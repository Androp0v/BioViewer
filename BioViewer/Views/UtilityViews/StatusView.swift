//
//  StatusView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import SwiftUI

struct StatusView: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            HStack (spacing: 8) {
                if proteinViewModel.statusRunning {
                    ProgressView()
                }
                Text("\(proteinViewModel.statusText)")
            }
            .padding(.horizontal, 8)
            if proteinViewModel.statusRunning && proteinViewModel.progress != nil {
                VStack {
                    Spacer()
                    ProgressView(value: proteinViewModel.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        }
        .cornerRadius(8)
    }

}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
            .frame(width: 300, height: 32)
    }
}
