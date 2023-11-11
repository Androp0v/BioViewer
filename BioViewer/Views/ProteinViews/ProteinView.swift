//
//  ContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

struct ProteinView: View {

    // MARK: - Properties

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var proteinDataSource: ProteinDataSource
    @EnvironmentObject var colorViewModel: ProteinColorViewModel
    @EnvironmentObject var statusViewModel: StatusViewModel
    @StateObject var toolbarConfig = ToolbarConfig()
    
    // Sidebar
    @State private var showInspector: Bool = UserDefaults.standard.bool(forKey: "showInspector") {
        didSet {
            guard horizontalSizeClass != .compact else { return }
            UserDefaults.standard.set(showInspector, forKey: "showInspector")
        }
    }
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
        
        VStack(spacing: 0) {
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
                    
                    // Status changes
                    StatusOverlayView()
                    
                    #if DEBUG
                    HStack {
                        Spacer()
                        VStack(spacing: .zero) {
                            Spacer()
                            ResolutionView(viewModel: ResolutionViewModel(proteinViewModel: proteinViewModel))
                            FPSCounterView(viewModel: FPSCounterViewModel(proteinViewModel: proteinViewModel))
                                .padding()
                        }
                    }
                    #endif
                    
                    // Top toolbar
                    VStack {
                        if UserDefaults.standard.value(forKey: "showToolbar") == nil {
                            TopToolbar(displayToolbar: horizontalSizeClass != .compact)
                        } else {
                            TopToolbar(displayToolbar: UserDefaults.standard.bool(forKey: "showToolbar"))
                        }
                        Spacer()
                    }
                    .environmentObject(toolbarConfig)
                    .onAppear {
                        proteinViewModel.toolbarConfig = toolbarConfig
                        toolbarConfig.proteinViewModel = proteinViewModel
                    }
                    
                    // Scene controls
                    VStack(spacing: 12) {
                        Spacer()
                        if proteinDataSource.files.first?.fileType == .dynamicStructure {
                            DynamicStructureControlView()
                                .environmentObject(proteinViewModel)
                        }
                        /*
                         if toggleSequenceView {
                         ProteinSequenceView()
                         .padding(.horizontal, 12)
                         .frame(minWidth: 32, maxWidth: sequenceViewMaxWidth)
                         }
                         */
                    }
                    .padding(.bottom, 12)
                    
                    // Import view
                    if proteinDataSource.proteinCount == 0 && !statusViewModel.isImportingFile {
                        ProteinImportView()
                            .edgesIgnoringSafeArea(.bottom)
                    }
                }
                .onDrop(of: [.data, .item], delegate: proteinViewModel.dropHandler)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Button to open right panel
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(
                    action: {
                        showInspector.toggle()
                    },
                    label: {
                        Image(systemName: horizontalSizeClass == .compact ? "gearshape" : "sidebar.trailing")
                    }
                )
            }
        }
        .inspector(isPresented: $showInspector) {
            ProteinSidebar(
                showSidebar: $showInspector,
                selectedSegment: $selectedSidebarSegment
            )
            .presentationDetents([.medium, .large])
            #if targetEnvironment(macCatalyst)
            .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
            #else
            .inspectorColumnWidth(min: 300, ideal: 400)
            #endif
        }
        // Inform command menus of focus changes
        .focusedValue(\.proteinViewModel, proteinViewModel)
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
