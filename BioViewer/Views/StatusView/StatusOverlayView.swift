//
//  StatusOverlayView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/11/23.
//

import SwiftUI

struct StatusOverlayView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    
    var body: some View {
        if let statusAction = statusViewModel.runningActions.first {
            HStack {
                VStack {
                    if !statusViewModel.isImportingFile {
                        Spacer()
                    }
                    BVProgressComponent(title: statusAction.type.title, progress: statusAction.progress)
                        .frame(alignment: .bottomLeading)
                        .padding()
                }
                if !statusViewModel.isImportingFile {
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    StatusOverlayView()
}
