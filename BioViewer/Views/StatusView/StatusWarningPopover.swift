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
            VStack(spacing: 0) {
                if statusViewModel.statusWarning.count == AppState.maxNumberOfWarnings {
                    Text(NSLocalizedString(
                        "Too many warnings found. Showing only the first \(AppState.maxNumberOfWarnings).", comment: "")
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background {
                            Color.orange
                                .opacity(0.8)
                        }
                }
                List {
                    ForEach(statusViewModel.statusWarning.reversed(), id: \.self) { warning in
                        Text(warning)
                            .listRowBackground(Color.clear)
                    }
                }
                Spacer()
                    .frame(height: 4)
            }
            .frame(minWidth: 300, minHeight: 600)
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
