//
//  CameraControlToolbar.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct CameraControlToolbar: View {
    
    @Environment(ToolbarConfig.self) var config: ToolbarConfig
        
    var body: some View {
        @Bindable var config = config
        HStack {
            Picker("Rotation mode", selection: $config.selectedTool) {
                Image(systemName: "rotate.3d")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: TopToolbar.Constants.buttonSize, height: TopToolbar.Constants.buttonSize)
                    .foregroundColor(.accentColor).tag(0)
                Image(systemName: "move.3d")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: TopToolbar.Constants.buttonSize, height: TopToolbar.Constants.buttonSize)
                    .foregroundColor(.accentColor).tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .foregroundColor(.accentColor)
            .frame(width: 4 * TopToolbar.Constants.buttonSize)
            .disabled(config.autorotating)
            .contextMenu {
                Button(role: .destructive) {
                    config.resetCamera()
                } label: {
                    Label("Reset camera", systemImage: "arrow.uturn.backward")
                }
            }
            Button(
                action: {
                    config.autorotating.toggle()
                }, label: {
                    Image(systemName: config.autorotating
                          ? "arrow.triangle.2.circlepath.circle.fill"
                          : "arrow.triangle.2.circlepath.circle"
                    )
                    .foregroundColor(.accentColor)
                }
            )
        }
    }
}

struct CameraControlToolbar_Previews: PreviewProvider {
    static var previews: some View {
        CameraControlToolbar()
            .environment(ToolbarConfig())
    }
}
