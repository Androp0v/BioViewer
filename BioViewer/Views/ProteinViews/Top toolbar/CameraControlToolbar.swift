//
//  CameraControlToolbar.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct CameraControlToolbar: View {
    
    @State var selectedTool: Int = 0
        
    var body: some View {
        Picker("Rotation mode", selection: $selectedTool) {
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
    }
}

struct CameraControlToolbar_Previews: PreviewProvider {
    static var previews: some View {
        CameraControlToolbar()
    }
}
