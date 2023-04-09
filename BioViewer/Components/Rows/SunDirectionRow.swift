//
//  SunDirectionRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/4/23.
//

import simd
import SwiftUI

struct SunDirectionRow: View {
    
    @Binding var theta: Angle
    @Binding var phi: Angle
    
    let sunFrameSize: CGFloat = 64
    #if targetEnvironment(macCatalyst)
    let spacing: CGFloat = 8
    #else
    let spacing: CGFloat = 12
    #endif
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
        
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Sun direction:")
            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundColor(.gray)
                        .opacity(0.75)
                        .zIndex(!(-90...90).contains(theta.degrees) ? 2.0 : 0.0)
                    Image(systemName: "sun.max.fill")
                        .offset(x: computeSunOffset(theta: theta, phi: phi).x)
                        .offset(y: computeSunOffset(theta: theta, phi: phi).y)
                        .zIndex(!(-90...90).contains(theta.degrees) ? 0.0 : 2.0)
                    // Theta path
                    Path { path in
                        var startOffset = computeSunOffset(
                            theta: Angle(degrees: -180),
                            phi: phi
                        )
                        startOffset.x += sunFrameSize / 2
                        startOffset.y += sunFrameSize / 2
                        path.move(to: startOffset)
                        for thetaValue in (-180...180).reversed() {
                            var offset = computeSunOffset(
                                theta: Angle(degrees: Double(thetaValue)),
                                phi: phi
                            )
                            offset.x += sunFrameSize / 2
                            offset.y += sunFrameSize / 2
                            path.addLine(to: offset)
                        }
                    }
                    .stroke(Color.accentColor, lineWidth: 3)
                    .zIndex(1.0)
                    // Phi path
                    Path { path in
                        path.move(to: CGPoint(x: sunFrameSize/2, y: 0))
                        for phiValue in (-90...90).reversed() {
                            var offset = computeSunOffset(
                                theta: theta,
                                phi: Angle(degrees: Double(phiValue))
                            )
                            offset.x += sunFrameSize / 2
                            offset.y += sunFrameSize / 2
                            path.addLine(to: offset)
                        }
                    }
                    .stroke(Color.accentColor, lineWidth: 3)
                    .zIndex(1.0)
                }
                .frame(width: sunFrameSize, height: sunFrameSize)
                VStack(alignment: .leading, spacing: .zero) {
                    HStack(spacing: .zero) {
                        Text("Latitude (")
                        TextField("", value: $phi.degrees, formatter: formatter)
                            .fixedSize()
                            .onChange(of: phi) { newValue in
                                if newValue.radians > .pi/2 {
                                    phi.radians = .pi/2
                                } else if newValue.radians < -.pi/2 {
                                    phi.radians = -.pi/2
                                }
                            }
                        Text("º)")
                        Spacer()
                    }
                    Slider(value: $phi.degrees, in: -90...90)
                    HStack(spacing: .zero) {
                        Text("Longitude (")
                        TextField("", value: $theta.degrees, formatter: formatter)
                            .fixedSize()
                            .onChange(of: theta) { newValue in
                                if newValue.radians > .pi {
                                    theta.radians = .pi
                                } else if newValue.radians < -.pi {
                                    theta.radians = -.pi
                                }
                            }
                        Text("º)")
                        Spacer()
                    }
                    Slider(value: $theta.degrees, in: -180...180)
                }
                .padding(.leading, 12)
            }
        }
        #if targetEnvironment(macCatalyst)
        .padding([.top, .leading], 8)
        #endif
    }
    
    func computeSunOffset(theta: Angle, phi: Angle) -> CGPoint {
        // let x = sunFrameSize / 2 * cos(theta) * sin(phi)
        let theta = Angle(degrees: theta.degrees - 90)
        let y = sunFrameSize / 2 * cos(theta.radians) * cos(phi.radians)
        let z = sunFrameSize / 2 * sin(phi.radians)
        return CGPoint(x: y, y: -z)
    }
}

struct SunDirectionRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SunDirectionRow(theta: .constant(Angle(degrees: 45)), phi: .constant(Angle(degrees: 90)))
        }
    }
}
