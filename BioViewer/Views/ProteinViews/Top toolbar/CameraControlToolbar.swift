//
//  CameraControlToolbar.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct CameraControlToolbar: View {
    
    @EnvironmentObject var config: ToolbarConfig
    @EnvironmentObject var proteinViewModel: ProteinViewModel
        
    var body: some View {
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
        .foregroundColor(.accentColor)
        .frame(width: 4 * TopToolbar.Constants.buttonSize)
        .contextMenu {
            Button(role: .destructive) {
                proteinViewModel.renderer.scene.resetCamera()
            } label: {
                Label("Reset camera", systemImage: "arrow.uturn.backward")
            }
        }
    }
}

struct CameraControlToolbar_Previews: PreviewProvider {
    static var previews: some View {
        CameraControlToolbar()
            .environmentObject(ToolbarConfig())
    }
}
