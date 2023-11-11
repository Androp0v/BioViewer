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
        if let statusAction = statusViewModel.actionToShow {
            HStack {
                VStack {
                    if !statusViewModel.isBlockingUI {
                        Spacer()
                    }
                    BVProgressComponent(
                        title: statusAction.type.title,
                        progress: statusAction.progress,
                        error: statusAction.error,
                        closeAction: statusAction.error == nil ? nil : {
                            statusViewModel.dismissAction(statusAction)
                        }
                    )
                    .frame(alignment: .bottomLeading)
                    .padding()
                }
                if !statusViewModel.isBlockingUI {
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    StatusOverlayView()
}
