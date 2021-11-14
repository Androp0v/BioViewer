//
//  FileSourceRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/11/21.
//

import SwiftUI

struct FileSourceRow: View {
    
    var lineNumber: Int
    var line: String
    var hasWarning: Bool
    
    var body: some View {
        ZStack {
            if hasWarning {
                Color.yellow
                    .opacity(0.3)
            }
            HStack {
                Text(String(lineNumber))
                    .frame(width: 36, alignment: .trailing)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white)
                Rectangle()
                    .padding(.vertical, 4)
                    .frame(width: 1)
                    .foregroundColor(Color(UIColor.opaqueSeparator))
                    .opacity(0.5)
                Text(line)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.trailing, 12)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.black)
        .listRowInsets(EdgeInsets())
    }
}

struct FileSourceRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FileSourceRow(lineNumber: 3352,
                          line: "ATOM  39812  OP2   C 01930      94.465 121.850 130.597  1.00113.26           O",
                          hasWarning: true)
        }
    }
}
