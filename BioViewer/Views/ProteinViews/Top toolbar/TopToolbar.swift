//
//  TopToolbar.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/12/21.
//

import SwiftUI

struct TopToolbar: View {
    
    let renderer: ProteinRenderer
    @State var displayToolbar: Bool
    @State var displayPhotoMode: Bool = false
    
    @Environment(ToolbarConfig.self) var config: ToolbarConfig
    
    #if targetEnvironment(macCatalyst) || os(macOS)
    let buttonStyle = PlainButtonStyle()
    #else
    let buttonStyle = DefaultButtonStyle()
    #endif
    
    struct Constants {
        #if targetEnvironment(macCatalyst) || os(macOS)
        static let toolbarSize: CGFloat = 28
        static let buttonSize: CGFloat = 16
        static let spacing: CGFloat = 12
        static let toggleCornerSize: CGFloat = 4
        #else
        static let toolbarSize: CGFloat = 44
        static let buttonSize: CGFloat = 24
        static let spacing: CGFloat = 16
        static let toggleCornerSize: CGFloat = 8
        #endif
    }
    
    var body: some View {
        ZStack {
            
            // Toolbar
            ZStack(alignment: .top) {
                if displayToolbar {
                    VStack(spacing: 0) {
                        HStack(spacing: Constants.spacing) {
                            Spacer()
                            Button(action: {
                                displayPhotoMode.toggle()
                            }, label: {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                                    .foregroundColor(.accentColor)
                            })
                                .sheet(isPresented: $displayPhotoMode) {
                                    if AppState.hasPhotoModeSupport() {
                                        PhotoModeView(renderer: renderer)
                                    } else {
                                        PhotoModeUnsupportedView()
                                    }
                                }
                            Divider()
                                .frame(height: Constants.buttonSize)
                            
                            CameraControlToolbar()
                            
                            Divider()
                                .frame(height: Constants.buttonSize)
                            Spacer()
                                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, Constants.spacing)
                        .background(.thickMaterial)
                        Divider()
                    }
                    .transition(.move(edge: .top))
                }
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .mask(Rectangle())
            
            // Toolbar toggle button
            HStack {
                Spacer()
                ZStack {
                    if !displayToolbar {
                        Rectangle()
                            .foregroundColor(.clear)
                            .background(.thickMaterial)
                            .mask(RoundedRectangle(cornerSize: CGSize(width: Constants.toggleCornerSize,
                                                                      height: Constants.toggleCornerSize))
                                    .padding(4))
                            .frame(width: Constants.buttonSize + 2 * Constants.spacing,
                                   height: Constants.toolbarSize)
                    }
                    Button(action: {
                        withAnimation {
                            displayToolbar.toggle()
                        }
                        UserDefaults.standard.set(displayToolbar, forKey: "showToolbar")
                    }, label: {
                        Image(systemName: "rectangle.topthird.inset.filled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                        .frame(width: Constants.buttonSize + 2 * Constants.spacing,
                               height: Constants.toolbarSize)
                    })
                        .buttonStyle(buttonStyle)
                }
            }
        }
        .frame(height: Constants.toolbarSize)
    }
}
