//
//  PhotoModeHeader.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeHeader: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private struct Constants {
        #if targetEnvironment(macCatalyst)
        static let spacing: CGFloat = 24
        #else
        static let spacing: CGFloat = 36
        #endif
    }
        
    var body: some View {
        if horizontalSizeClass == .compact {
            VStack {
                Rectangle()
                    .background(.black)
                    .aspectRatio(1.0, contentMode: .fit)
                PhotoModeConfigList()
            }
        } else {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: Constants.spacing) {
                    Rectangle()
                        .background(.black)
                        .frame(width: min(geometry.size.width * 0.4, geometry.size.height),
                               height: min(geometry.size.width * 0.4, geometry.size.height))
                    PhotoModeConfigList()
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 400)
        }
    }
}

struct PhotoModeHeader_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeHeader()
    }
}
