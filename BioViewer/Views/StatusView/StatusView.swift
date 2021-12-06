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
    static let statusTextSpinnerPadding: CGFloat = 2
    static let warningButtonHorizontalPadding: CGFloat = 0
    static let warningIconSize: CGFloat = 10
    #else
    static let height: CGFloat = 32
    static let cornerRadius: CGFloat = 8
    static let statusTextSpinnerPadding: CGFloat = 8
    static let warningButtonHorizontalPadding: CGFloat = 8
    static let warningIconSize: CGFloat = 14
    #endif
}

struct StatusView: View {

    @ObservedObject var statusViewModel: StatusViewModel
    @State var showErrorPopover: Bool = false
    @State var showWarningPopover: Bool = false

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            HStack(spacing: 0) {
                if !(statusViewModel.statusWarning.isEmpty) || !(statusViewModel.statusError ?? "").isEmpty {
                    Group {
                        if !(statusViewModel.statusWarning.isEmpty) && (statusViewModel.statusError ?? "").isEmpty {
                            // Show warnings only if there's no errors
                            Button(action: {
                                showWarningPopover.toggle()
                            },
                                   label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .padding(.horizontal, StatusViewConstants.warningButtonHorizontalPadding)
                                    .frame(maxHeight: .infinity)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 12, height: 12)
                                    .font(.system(size: StatusViewConstants.warningIconSize))
                            })
                                .popover(isPresented: $showWarningPopover) {
                                    StatusWarningPopover(statusViewModel: statusViewModel)
                                }
                        } else if !(statusViewModel.statusError ?? "").isEmpty {
                            Button(action: {
                                showErrorPopover.toggle()
                            },
                                   label: {
                                Image(systemName: "xmark.octagon.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .padding(.horizontal, StatusViewConstants.warningButtonHorizontalPadding)
                                    .frame(maxHeight: .infinity)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 12, height: 12)
                                    .font(.system(size: StatusViewConstants.warningIconSize))
                            })
                                .popover(isPresented: $showErrorPopover) {
                                    StatusErrorPopover(statusViewModel: statusViewModel)
                                }
                        }
                        Rectangle()
                            .padding(.vertical, 4)
                            .frame(width: 1)
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                            .opacity(0.5)
                    }
                }
                if statusViewModel.statusRunning {
                    ProgressView()
                        .padding(.leading, 8)
                        .progressViewStyle(CircularProgressViewStyle())
                        #if targetEnvironment(macCatalyst)
                        // Spinner is weirdly big on Catalyst (Monterey)
                        .scaleEffect(x: 0.4, y: 0.4)
                        #endif
                }
                Text("\(statusViewModel.statusText)")
                    .padding(.leading, StatusViewConstants.statusTextSpinnerPadding + 8)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity)
            }
            if statusViewModel.statusRunning {
                VStack(spacing: 0) {
                    Spacer()
                    CustomLinearProgressView(value: statusViewModel.progress, total: 1.0)
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
