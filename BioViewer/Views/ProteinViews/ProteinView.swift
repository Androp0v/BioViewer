//
//  ContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ProteinView: View {

    // MARK: - Properties

    @EnvironmentObject var proteinViewModel: ProteinViewModel

    // Sidebar
    @State private var showSidebar = UserDefaults.standard.bool(forKey: "showSidebar") {
        didSet {
            UserDefaults.standard.set(showSidebar, forKey: "showSidebar")
        }
    }
    @State private var toggleModalSidebar = false
    @State private var selectedSidebarSegment = 0

    // Sequence view
    @State private var toggleSequenceView = false
    @State private var sequenceViewMaxWidth: CGFloat = .infinity

    // UI constants
    private enum Constants {
        static let compactSequenceViewWidth: CGFloat = 32
    }

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // MARK: - Body

    // Main view
    var body: some View {
        
        let sidebar = ProteinSidebar(selectedSegment: $selectedSidebarSegment)
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Future toolbar items will be here
                Rectangle()
                    .frame(height: 8)
                    .foregroundColor(Color(UIColor.systemBackground))
                // Separator
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.opaqueSeparator))
                // Main view here (including sidebar)
                HStack(spacing: 0) {
                    // Main scene container
                    ZStack {

                        // Main scene view
                        ProteinMetalView(proteinViewModel: proteinViewModel)
                            .background(.black)
                            .edgesIgnoringSafeArea([.top, .bottom])

                        // Import view
                        if proteinViewModel.proteinCount == 0 {
                            ProteinImportView()
                        }

                        // Scene controls
                        VStack(spacing: 12) {
                            Spacer()
                            ProteinCameraControlView()
                            if toggleSequenceView {
                                ProteinSequenceView()
                                    .padding(.horizontal, 12)
                                    .frame(minWidth: 32, maxWidth: sequenceViewMaxWidth)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .onDrop(of: [.data, .item], delegate: proteinViewModel.dropDelegate)

                    // Sidebar
                    if showSidebar {
                        sidebar
                            .frame(width: 300)
                            .edgesIgnoringSafeArea([.horizontal, .bottom])
                            .transition(AnyTransition.move(edge: .trailing))
                    }

                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Button to open right panel
                ToolbarItem(placement: .navigationBarTrailing) {
                    if horizontalSizeClass == .compact {
                        Button(action: {
                            toggleModalSidebar.toggle()
                        },
                               label: {
                            Image(systemName: "gearshape")
                        })
                    } else {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSidebar.toggle()
                            }
                        },
                               label: {
                            Image(systemName: "sidebar.trailing")
                        })
                        
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    // Status bar component
                    StatusView(statusViewModel: proteinViewModel.statusViewModel)
                        .frame(minWidth: 0,
                               idealWidth: geometry.size.width * 0.6,
                               maxWidth: geometry.size.width * 0.6,
                               minHeight: StatusViewConstants.height,
                               idealHeight: StatusViewConstants.height,
                               maxHeight: StatusViewConstants.height,
                               alignment: .center)
                }
            }
            .sheet(isPresented: $toggleModalSidebar, content: {
                sidebar
            })
        }
        .environmentObject(proteinViewModel)
    }

    // MARK: - Public functions
    /// Called when the ProteinSceneView is tapped, to check if the protein sequence
    /// view widget should be shown or not.
    /// - Parameter nodeHit: Wether a node was tapped  (```true```) or
    /// not (```false```).
    public func didTapScene(nodeHit: Bool) {
        // If a node was hit and the sequence view widget is
        // not shown, show it.
        if nodeHit && toggleSequenceView == false {
            animateSequenceView()
            return
        }
        // If the view was tapped outside a node and the sequence
        // view widget is shown, dismiss it.
        if !nodeHit && toggleSequenceView == true {
            animateSequenceView()
            return
        }
    }

    // MARK: - Private functions

    /// Animate collapsing or inflating the sequence view widget
    private func animateSequenceView() {
        if toggleSequenceView == true {
            // Collapse sequence view
            withAnimation(.easeInOut(duration: 0.15)) {
                sequenceViewMaxWidth = Constants.compactSequenceViewWidth
            }
            withAnimation(.easeInOut(duration: 0.05).delay(0.1)) {
                toggleSequenceView.toggle()
            }
        } else {
            // Inflate sequence view
            withAnimation(.easeInOut(duration: 0.1)) {
                toggleSequenceView.toggle()
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                sequenceViewMaxWidth = .infinity
            }
        }
    }

}

struct ProteinView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinView()
            .previewDevice("iPhone SE (2nd generation)")
            .environmentObject(ProteinViewModel())
    }
}
