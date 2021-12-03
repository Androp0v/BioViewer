//
//  UnitTextView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 3/12/21.
//

// swiftlint:disable shorthand_operator

import SwiftUI

/// Use _{...} for subscript, ^{...}  for superscript.
struct UnitTextView: View {
    
    let inputString: String
    let baseLine: CGFloat
    
    private enum Constants {
        // TO-DO: Compute baseline and size from default font size to avoid
        // issues with Dynamic Type.
        #if targetEnvironment(macCatalyst)
        static let subOrSuperscriptFontSize: CGFloat = 8
        #else
        static let subOrSuperscriptFontSize: CGFloat = 12
        #endif
    }
    
    var body: some View {
        
        var string = inputString
        var text = Text("")
        
        while let validIndex = string.firstIndex(where: { (char) -> Bool in  return (char == "_" || char == "^") }) {
            
            let mySubstringP1 = string[..<validIndex]
            var mySubstringP2 = string[validIndex...]
            
            text = text + Text(mySubstringP1)
            
            if mySubstringP2.count < 3 {
                return text + Text(mySubstringP2)
            }
            
            var subscriptType = mySubstringP2.first!
            mySubstringP2 = mySubstringP2.dropFirst()
            
            var subScriptString = ""
            if mySubstringP2.first != "{" {
                subScriptString.append(String(subscriptType))
                subscriptType = Character(" ")
            } else if let subStringIndex = mySubstringP2.firstIndex(where: { (char) -> Bool in  return (char == "}") }) {
                mySubstringP2 = mySubstringP2.dropFirst()
                subScriptString = String(mySubstringP2[..<subStringIndex])
                mySubstringP2 = mySubstringP2[subStringIndex...].dropFirst()
            } else {
                return Text("")
            }
            
            switch subscriptType {
            case "^":
                text = text + Text(subScriptString)
                    .baselineOffset(baseLine)
                    .font(.system(size: Constants.subOrSuperscriptFontSize))
            case "_":
                text = text + Text(subScriptString)
                    .baselineOffset(-1 * baseLine)
                    .font(.system(size: Constants.subOrSuperscriptFontSize))
            default:
                text = text + Text(subScriptString)
            }
            string = String(mySubstringP2)
        }
        
        text = text + Text(string)
        
        return text
    }
}

struct UnitTextView_Previews: PreviewProvider {
    static var previews: some View {
        UnitTextView(inputString: "Å^{3}", baseLine: 8.0)
    }
}
