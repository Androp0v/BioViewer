//
//  SwitchRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/5/21.
//

import Foundation
import SwiftUI

struct SwitchRow: View {

    var title: String
    @Binding var toggledVariable: Bool

    var body: some View {
        #if targetEnvironment(macCatalyst)
        Toggle(title, isOn: $toggledVariable)
            .tint(.accentColor)
        #else
        Toggle(title, isOn: $toggledVariable.animation())
            .tint(.accentColor)
        #endif
    }

}

struct SwitchRow_Previews: PreviewProvider {
    static var previews: some View {
        SwitchRow(title: "Sample toggle", toggledVariable: .constant(true))
    }
}
