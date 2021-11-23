//
//  FileAtomElementPopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import SwiftUI

struct FileAtomElementPopover: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    @State var carbonFraction: CGFloat = 0.0
    @State var oxygenFraction: CGFloat = 0.0
    @State var nitrogenFraction: CGFloat = 0.0
    
    private enum AnimationConstants {
        static let duration: Double = 0.8
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .trim(from: 0, to: nitrogenFraction)
                    .stroke(Color.blue,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: AnimationConstants.duration)) {
                            self.nitrogenFraction = 1.0
                        }
                    }
                Circle()
                    .trim(from: 0, to: oxygenFraction)
                    .stroke(Color.red,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: AnimationConstants.duration)) {
                            self.oxygenFraction = 0.7
                        }
                    }
                
                // Carbon
                Circle()
                    .trim(from: 0, to: carbonFraction)
                    .stroke(Color.green,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: AnimationConstants.duration)) {
                            self.carbonFraction = 0.4
                        }
                    }
            }
            .padding(64)
            .frame(width: 250, height: 250)
            Text("Carbon: 18820 (40%)")
            Text("Oxygen: 13333 (30%)")
            Text("Nitrogen: 12990 (30%)")
            Divider()
                .padding(.horizontal, 64)
            Text("Total: 58330 (100%)")
        }
    }
}

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementPopover()
    }
}
