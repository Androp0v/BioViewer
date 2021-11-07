//
//  StatusWarningPopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/11/21.
//

import SwiftUI

struct StatusWarningPopover: View {
    
    @ObservedObject var statusViewModel: StatusViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private struct StatusWarningPopoverContent: View {
        
        @ObservedObject var statusViewModel: StatusViewModel
        
        var body: some View {
            VStack {
                Spacer()
                    .frame(height: 4)
                List {
                    ForEach(statusViewModel.statusWarning.reversed(), id: \.self) { warning in
                        Text(warning)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .frame(minWidth: 300, minHeight: 200)
            .background(.thinMaterial)
            .listStyle(.plain)
        }
        
    }
    
    var body: some View {
        
        if horizontalSizeClass == .compact {
            NavigationView {
                StatusWarningPopoverContent(statusViewModel: statusViewModel)
                    .navigationTitle(NSLocalizedString("Warnings", comment: ""))
            }
            .navigationBarTitleDisplayMode(.inline)
        } else {
            StatusWarningPopoverContent(statusViewModel: statusViewModel)
        }
    }
}

struct StatusWarningPopover_Previews: PreviewProvider {
    static var previews: some View {
        StatusWarningPopover(statusViewModel: StatusViewModel())
    }
}
