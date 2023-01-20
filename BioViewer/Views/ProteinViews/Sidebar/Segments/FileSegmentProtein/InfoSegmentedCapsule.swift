//
//  InfoAtomsCapsule.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/3/22.
//

import SwiftUI

struct InfoCapsuleSegment: Hashable {
    let id = UUID()
    let fraction: Double
    let color: Color
}

struct InfoSegmentedCapsule: View {
    
    let segments: [InfoCapsuleSegment]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: .zero) {
                ForEach(segments, id: \.self) { segment in
                    segment.color
                        .frame(width: segment.fraction * geometry.size.width)
                }
            }
        }
        .frame(height: 6)
        .mask(Capsule()
                .frame(height: 6)
        )
    }
}

/*
struct InfoAtomsCapsule_Previews: PreviewProvider {
    static var previews: some View {
        InfoAtomsCapsule()
            .environmentObject(ProteinViewModel())
    }
}
*/
