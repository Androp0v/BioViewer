//
//  ContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import Combine
import SwiftUI
import SceneKit
import UIKit
import UniformTypeIdentifiers
struct ProteinView: View {

    // MARK: - Properties
    @State var scene: SCNScene
    @State var sceneDelegate: ProteinViewSceneDelegate
    @State var dataSource: ProteinViewDataSource
    private var dropDelegate: ImportDroppedFilesDelegate
    private var cameraNode: SCNNode

    private var sceneBackgroundColorCancellable: AnyCancellable?

    // MARK: - UI variables/constants

    // Sidebar
    @State var toggleSidebar = false
    @State var toggleModalSidebar = false

    // Sequence view
    @State var toggleSequenceView = false
    @State var sequenceViewMaxWidth: CGFloat = .infinity

    // UI constants
    private enum Constants {
        static let compactSequenceViewWidth: CGFloat = 32
    }

    // MARK: - Initialization

    init() {

        // Open SceneKit scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        self.scene = scene

        // Setup scene delegate and datasource
        let sceneDelegate = ProteinViewSceneDelegate()
        let dataSource = ProteinViewDataSource(sceneDelegate: sceneDelegate)
        self.sceneDelegate = sceneDelegate
        self.dataSource = dataSource
        sceneDelegate.scene = scene
        sceneDelegate.dataSource = dataSource

        // Setup drop delegate
        self.dropDelegate = ImportDroppedFilesDelegate(dataSource: dataSource)

        // Setup camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
        self.cameraNode.camera?.zFar = 1000
        scene.rootNode.addChildNode(cameraNode)

        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 0)
        scene.rootNode.addChildNode(lightNode)

        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // Set scene background color (listening for changes)
        sceneBackgroundColorCancellable = sceneDelegate.$sceneBackground.sink { [self] color in
            // This might reset the scene camera position, unsure why
            self.scene.background.contents = UIColor(color)
        }

    }

    // MARK: - Body

    // Main view
    var body: some View {
        GeometryReader { geometry in
            VStack (spacing: 0) {
                // Future toolbar items will be here
                Rectangle()
                    .frame(height: 8)
                    .foregroundColor(Color(UIColor.systemBackground))
                // Separator
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.opaqueSeparator))
                // Main view here (including sidebar)
                HStack (spacing: 0) {
                    // Main scene container
                    ZStack {

                        // Main scene view
                        ProteinSceneView(parent: self,
                                         scene: $scene,
                                         sceneDelegate: $sceneDelegate)
                        .background(sceneDelegate.sceneBackground)
                        .onDrop(of: [.data], delegate: dropDelegate)
                        /*.gesture(
                            TapGesture()
                                .onEnded( {
                                    animateSequenceView()
                                })
                        )*/
                        .edgesIgnoringSafeArea([.top, .bottom])

                        // Scene controls
                        VStack (spacing: 12) {
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

                    // Sidebar
                    if toggleSidebar {
                        ProteinSidebar()
                            .frame(width: 300)
                            .edgesIgnoringSafeArea([.horizontal, .bottom])
                    }

                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Button to open right panel
                ToolbarItem(placement: .navigationBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .phone
                        || geometry.size.width < 600 {
                        Button(action: {
                            toggleModalSidebar.toggle()
                        }) {
                            Image(systemName: "gearshape")
                        }
                        .sheet(isPresented: $toggleModalSidebar, content: {
                            ProteinSidebar()
                        })
                    } else {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)){
                                toggleSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.trailing")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    // Status bar component
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(Text("Idle"))
                        .cornerRadius(8)
                        .frame(minWidth: 0,
                               idealWidth: geometry.size.width * 0.6,
                               maxWidth: geometry.size.width * 0.6,
                               minHeight: 32,
                               idealHeight: 32,
                               maxHeight: 32,
                               alignment: .center)
                }
            }
        }
        .environmentObject(sceneDelegate)
        .environmentObject(dataSource)
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
    }
}
