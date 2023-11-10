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

struct ProteinSidebar: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedSegment: Int

    // MARK: - View body
    
    var body: some View {
        ZStack(alignment: .top) {
            switch selectedSegment {
            case 0:
                FileSegmentProtein()
            case 1:
                AppearanceSegmentProtein()
            case 2:
                GraphicsSettingsSegment()
            default:
                Spacer()
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .safeAreaInset(edge: .top) {
            // Top segmented control to switch between options
            VStack(spacing: .zero) {
                header
                    .background(.thinMaterial)
                Divider()
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder private var header: some View {
        VStack(spacing: .zero) {
            if horizontalSizeClass == .compact {
                ZStack(alignment: .leading) {
                    Button(
                        action: {
                            dismiss()
                        },
                        label: {
                            closeImage
                        }
                    )
                    .padding(.leading, 8)
                    Text(NSLocalizedString("Inspector", comment: ""))
                        .bold()
                        .frame(maxWidth: .infinity)
                        .navigationBarHidden(true)
                }
                .padding(.top, 12)
            }
            Picker("Option", selection: $selectedSegment) {
                SidebarItem(image: "doc", tag: 0)
                SidebarItem(image: "camera.filters", tag: 1)
                /*
                 SidebarItem(image: "wrench.and.screwdriver", tag: 2)
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
    }
    
    // MARK: - Close button
    
    @ViewBuilder private var closeImage: some View {
        ZStack {
            Group {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .foregroundStyle(.regularMaterial)
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .foregroundStyle(Color(uiColor: .label))
                    .opacity(0.3)
            }
            .padding(4)
            .frame(width: 36, height: 36)
        }
    }
}

struct ProteinSidebar_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSidebar(selectedSegment: .constant(0))
            .previewLayout(.sizeThatFits)
    }
}
