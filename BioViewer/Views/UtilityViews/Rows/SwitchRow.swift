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
        Toggle(title, isOn: $toggledVariable)
    }

}

struct SwitchRow_Previews: PreviewProvider {
    static var previews: some View {
        SwitchRow(title: "Sample toggle", toggledVariable: .constant(true))
    }
}
