//
//  SequenceView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/5/21.
//

import SwiftUI

struct SequenceView: View {

    init() {
        UITableViewCell.appearance().backgroundColor = .secondarySystemBackground
        UITableView.appearance().backgroundColor = .secondarySystemBackground
    }

    var body: some View {
        GeometryReader { geometry in
            VStack (spacing: 0) {
                // Future toolbar items will be here
                Rectangle()
                    .frame(height: 8)
                    .foregroundColor(Color(UIColor.systemBackground))
                // Main sequences view
                VStack {

                    ScrollView(.horizontal) {
                        ScrollView(.vertical) {
                            LazyVStack {
                                SequenceRow()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor.separator))
                                    .padding(.leading, 24)
                                SequenceRow()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor.separator))
                                    .padding(.leading, 24)
                                SequenceRow()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor.separator))
                                    .padding(.leading, 24)
                                SequenceRow()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor.separator))
                                    .padding(.leading, 24)
                                SequenceRow()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor.separator))
                                    .padding(.leading, 24)
                            }
                            .padding(.top, 8)
                        }
                    }

                }
                .background(Color(UIColor.secondarySystemBackground))
                .edgesIgnoringSafeArea([.top, .bottom])
                //.onDrop(of: [.data], delegate: nil)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Button to open right panel
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // TO-DO
                            print("Inspector button tapped!")
                        }) {
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Image(systemName: "gearshape")
                            } else {
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
        .background(Color.green)
    }
}

struct SequenceView_Previews: PreviewProvider {
    static var previews: some View {
        SequenceView()
    }
}
