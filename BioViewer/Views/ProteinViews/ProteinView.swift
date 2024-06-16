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
    
    let proteinViewModel: ProteinViewModel
    let renderer: ProteinRenderer

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Environment(ProteinDataSource.self) var proteinDataSource: ProteinDataSource
    @Environment(ProteinColorViewModel.self) var colorViewModel: ProteinColorViewModel
    @Environment(StatusViewModel.self) var statusViewModel: StatusViewModel
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
        
    @State private var resolutionViewModel: ResolutionViewModel
    @State private var fpsViewModel: FPSCounterViewModel
    @State private var showSidebar: Bool = UserDefaults.standard.bool(forKey: "showSidebar")
    @State private var showInspectorModal: Bool = false
    @State private var selectedSidebarSegment = 0

    // Sequence view
    @State private var toggleSequenceView = false
    @State private var sequenceViewMaxWidth: CGFloat = .infinity

    // UI constants
    private enum Constants {
        static let compactSequenceViewWidth: CGFloat = 32
    }
    
    init(proteinViewModel: ProteinViewModel, renderer: ProteinRenderer) {
        self.proteinViewModel = proteinViewModel
        self.renderer = renderer
        self.resolutionViewModel = ResolutionViewModel(renderer: renderer)
        self.fpsViewModel = FPSCounterViewModel(renderer: renderer)
    }

    // MARK: - Body

    // Main view
    var body: some View {
        
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.opaqueSeparator)
            // Main view here (including sidebar)
            HStack(spacing: 0) {
                // Main scene container
                ZStack {
                    
                    // Main scene view
                    ProteinMetalView(
                        proteinViewModel: proteinViewModel,
                        selectionModel: selectionModel
                    )
                    .background(.black)
                    .edgesIgnoringSafeArea([.top, .bottom])
                    
                    // Status changes
                    StatusOverlayView()
                    
                    #if DEBUG
                    HStack {
                        Spacer()
                        VStack(spacing: .zero) {
                            Spacer()
                            ResolutionView()
                                .environment(resolutionViewModel)
                            FPSCounterView()
                                .environment(fpsViewModel)
                                .padding()
                        }
                    }
                    #endif
                    
                    // Top toolbar
                    VStack {
                        if UserDefaults.standard.value(forKey: "showToolbar") == nil {
                            TopToolbar(
                                renderer: renderer,
                                displayToolbar: horizontalSizeClass != .compact
                            )
                        } else {
                            TopToolbar(
                                renderer: renderer,
                                displayToolbar: UserDefaults.standard.bool(forKey: "showToolbar")
                            )
                        }
                        Spacer()
                    }
                    .environment(proteinViewModel.toolbarConfig)
                    
                    // Scene controls
                    VStack(spacing: 12) {
                        Spacer()
                        if proteinDataSource.files.first?.fileType == .dynamicStructure {
                            DynamicStructureControlView(renderer: renderer)
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
                    
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            VStack {
                                Spacer()
                                HStack {
                                    if selectionModel.selectionActive {
                                        SelectedAtom()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxHeight: 256)
                    }
                    
                    // Import view
                    if proteinDataSource.proteinCount == 0 && !statusViewModel.isImportingFile {
                        ProteinImportView()
                            .edgesIgnoringSafeArea(.bottom)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
                .onDrop(of: [.data, .item], delegate: proteinViewModel.dropHandler)
            }
        }
        .navigationTitle(proteinDataSource.files.first?.fileNameWithExtension ?? "BioViewer")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Button to open right panel
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(
                    action: {
                        showInspectorBinding(for: horizontalSizeClass).wrappedValue.toggle()
                    },
                    label: {
                        Image(systemName: horizontalSizeClass == .compact ? "gearshape" : "sidebar.trailing")
                    }
                )
            }
        }
        #endif
        .inspector(isPresented: showInspectorBinding(for: horizontalSizeClass)) {
            ProteinSidebar(
                showSidebar: showInspectorBinding(for: horizontalSizeClass),
                selectedSegment: $selectedSidebarSegment
            )
            .presentationDetents([.medium, .large])
            #if targetEnvironment(macCatalyst)
            .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
            #else
            .inspectorColumnWidth(min: 300, ideal: 400)
            #endif
        }
        .onChange(of: showSidebar) {
            UserDefaults.standard.setValue(showSidebar, forKey: "showSidebar")
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
    
    /// Whether the sidebar inspector is shown should be persistent, while it should always default to not shown
    /// on compact sizes.
    private func showInspectorBinding(for horizontalSizeClass: UserInterfaceSizeClass?) -> Binding<Bool> {
        if horizontalSizeClass == .compact {
            return $showInspectorModal
        } else {
            return $showSidebar
        }
    }

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
