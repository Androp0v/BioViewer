//
//  StatusErrorPopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/11/21.
//

import SwiftUI

struct StatusErrorPopover: View {
    
    @ObservedObject var statusViewModel: StatusViewModel
    
    var body: some View {
        ZStack {
            Color.red
                .opacity(0.8)
            Text(statusViewModel.statusError ?? "")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StatusErrorPopover_Previews: PreviewProvider {
    static var previews: some View {
        StatusErrorPopover(statusViewModel: StatusViewModel())
    }
}
