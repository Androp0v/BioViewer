//
//  ProteinSidebar.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

private struct SidebarItem: View {
    let image: String
    let tag: Int

    var body: some View {
        Image(systemName: image).tag(tag)
    }
}

struct ProteinSidebar: View {

    @State private var selectedSegment = 0
    @EnvironmentObject var sceneDelegate: ProteinViewSceneDelegate

    var body: some View {
        ZStack {
            // Options views go here
            switch(selectedSegment) {
            case 0: FileSegmentProtein()
            case 1: AppearanceSegmentProtein()
            default: Spacer()
            }
            // Top segemented control to switch between options
            VStack (spacing: 0) {
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                    Picker("Option", selection: $selectedSegment) {
                        SidebarItem(image: "doc", tag: 0)
                        SidebarItem(image: "camera.filters", tag: 1)
                        SidebarItem(image: "function", tag: 2)
                        SidebarItem(image: "gearshape.2", tag: 3)
                    }
                    .padding()
                    .pickerStyle(SegmentedPickerStyle())
                }
                .frame(height: 64)
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator))
                Spacer()
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct ProteinSidebar_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSidebar()
    }
}
