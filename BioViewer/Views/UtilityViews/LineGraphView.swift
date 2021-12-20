//
//  LineGraphView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct LineGraphView: View {
    
    @State var values: [Float]?
    
    enum Constants {
        #if targetEnvironment(macCatalyst)
        static let cornerRadius: CGFloat = 12
        static let buttonSize: CGFloat = 12
        #else
        static let cornerRadius: CGFloat = 24
        static let buttonSize: CGFloat = 16
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(NSLocalizedString("Energy", comment: ""))
                            .foregroundColor(.white)
                            .bold()
                            #if targetEnvironment(macCatalyst)
                            .padding(8)
                            #else
                            .padding()
                            #endif
                        Spacer()
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                            .foregroundColor(.white)
                            #if targetEnvironment(macCatalyst)
                            .padding(8)
                            #else
                            .padding()
                            #endif
                    }
                    ZStack(alignment: .center) {
                        GeometryReader { geometry in
                            
                            // Graph delimiters
                            Path { path in
                                path.move(to: CGPoint(x: 0,
                                                      y: 0))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: 0))
                                path.move(to: CGPoint(x: 0,
                                                      y: geometry.size.height / 4))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: geometry.size.height / 4))
                                path.move(to: CGPoint(x: 0,
                                                      y: geometry.size.height / 2))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: geometry.size.height / 2))
                                path.move(to: CGPoint(x: 0,
                                                      y: geometry.size.height * 3 / 4))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: geometry.size.height * 3 / 4))
                                path.move(to: CGPoint(x: 0,
                                                      y: geometry.size.height))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: geometry.size.height))
                            }
                            .strokedPath(StrokeStyle(lineWidth: 1.0, dash: [5.0]))
                            .foregroundColor(.white.opacity(0.5))
                            
                            if values == nil {
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                                    .foregroundColor(.white.opacity(0.75))
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height)
                                    .shadow(color: .black.opacity(0.2),
                                            radius: 12,
                                            x: 0,
                                            y: 10)
                            }
                            
                            // Data
                            /*
                            Path { path in
                                path.move(to: CGPoint(x: 0,
                                                      y: 0))
                                path.addLine(to: CGPoint(x: geometry.size.width / 4,
                                                         y: geometry.size.height / 1.5))
                                path.addLine(to: CGPoint(x: geometry.size.width / 2,
                                                         y: geometry.size.height / 8))
                                path.addLine(to: CGPoint(x: geometry.size.width * 3 / 4,
                                                         y: geometry.size.height))
                                path.addLine(to: CGPoint(x: geometry.size.width,
                                                         y: geometry.size.height / 7))
                            }
                            .strokedPath(StrokeStyle(lineWidth: 2.0))
                            .foregroundColor(.white)
                            */
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                        .frame(height: 1.5 * Constants.cornerRadius)
                }
            }
            .mask(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .frame(maxWidth: .infinity)
            #if targetEnvironment(macCatalyst)
            .padding(.top, 4)
            .padding(.bottom)
            #else
            .padding(.vertical)
            #endif
            .aspectRatio(1.4, contentMode: .fit)
            .shadow(color: .black.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 10)
            Text(NSLocalizedString("Maximum: 37.8, Minimum: 26.6", comment: ""))
        }
    }
}

struct LineGraphView_Previews: PreviewProvider {
    static var previews: some View {
        LineGraphView()
            .padding()
    }
}
