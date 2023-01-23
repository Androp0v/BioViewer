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
        Image(systemName: image)
            .symbolRenderingMode(.monochrome)
            .tag(tag)
    }
}

private struct ProteinSidebarContent: View {

    @Binding var selectedSegment: Int

    var body: some View {
        ZStack(alignment: .top) {
            switch selectedSegment {
            case 0:
                FileSegmentProtein()
            case 1:
                AppearanceSegmentProtein()
            case 2:
                FunctionsSegmentProtein()
            case 3:
                TrajectorySegmentProtein()
            case 4:
                SettingsSegmentProtein()
            default:
                Spacer()
            }
            // Top segmented control to switch between options
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Picker("Option", selection: $selectedSegment) {
                        SidebarItem(image: "doc", tag: 0)
                        SidebarItem(image: "camera.filters", tag: 1)
                        /*
                        SidebarItem(image: "function", tag: 2)
                        if proteinViewModel.dataSource.files.first?.fileType == .dynamicStructure {
                            SidebarItem(image: "video", tag: 3)
                        }
                        SidebarItem(image: "gearshape.2", tag: 3)
                        */
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(12)
                }
                .background(.thinMaterial)
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator))
                Spacer()
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct ProteinSidebar: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSegment: Int

    var body: some View {
        if horizontalSizeClass == .compact {
            NavigationView {
                ProteinSidebarContent(selectedSegment: $selectedSegment)
                    .background(Color(UIColor.secondarySystemBackground))
                    .navigationBarTitle(NSLocalizedString("Inspector", comment: ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(leading: Button(NSLocalizedString("Close", comment: "")) {
                        dismiss()
                    })
            }
        } else {
            HStack(spacing: 0) {
                Divider()
                ProteinSidebarContent(selectedSegment: $selectedSegment)
            }
        }
    }
}

struct ProteinSidebar_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSidebar(selectedSegment: .constant(0))
            .previewLayout(.sizeThatFits)
    }
}
