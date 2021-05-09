//
//  ContentView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

import SwiftUI
import SceneKit
import UIKit

struct ProteinView: View {

    // MARK: - Properties
    private var scene: SCNScene
    private var sceneDelegate: ProteinViewSceneDelegate
    private var dropDelegate: ImportDroppedFilesDelegate
    private var cameraNode: SCNNode

    // MARK: - Initialization

    init() {

        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().backgroundColor = .clear

        // Open SceneKit scene
        self.scene = SCNScene(named: "art.scnassets/ship.scn")!

        // Setup scene delegate
        self.sceneDelegate = ProteinViewSceneDelegate()
        sceneDelegate.scene = scene

        // Setup drop delegate
        self.dropDelegate = ImportDroppedFilesDelegate(sceneDelegate: self.sceneDelegate)

        // Setup camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
        self.cameraNode.camera?.zFar = 1000
        scene.rootNode.addChildNode(cameraNode)

        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 0)
        scene.rootNode.addChildNode(lightNode)

        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

    }

    // MARK: - Body
    @State var toggleSidebar = false
    @State var toggleModalSidebar = false

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
                    // Main SceneKit view
                    SceneView(scene: scene,
                              pointOfView: cameraNode,
                              options: [.autoenablesDefaultLighting,
                                        .allowsCameraControl,],
                              delegate: sceneDelegate)
                    .background(Color.black)
                    .onDrop(of: [.data], delegate: dropDelegate)
                    .edgesIgnoringSafeArea([.top, .bottom])
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
                ToolbarItemGroup(placement: .principal) {
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
    }

}

struct ProteinView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinView()
    }
}
