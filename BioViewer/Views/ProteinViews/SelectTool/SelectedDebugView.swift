//
//  SelectedDebugView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import SwiftUI

@MainActor struct SelectedDebugView: View {
    
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
    
    let numberFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var screenSpaceText: String {
        guard let x = selectionModel.lastHitPointInScreenSpace?.x else {
            return "-"
        }
        guard let y = selectionModel.lastHitPointInScreenSpace?.y else {
            return "-"
        }
        let xString = numberFormatter.string(from: NSNumber(floatLiteral: x)) ?? "??"
        let yString = numberFormatter.string(from: NSNumber(floatLiteral: y)) ?? "??"
        
        return "(\(xString), \(yString))"
    }
    
    var clipSpacePointText: String {
        return simdFormat(selectionModel.lastHitPointInClipSpace?.xyz)
    }
    
    var clipSpaceRayOriginText: String {
        return simdFormat(selectionModel.lastClipSpaceRay?.origin)
    }
    var clipSpaceRayDirectionText: String {
        return simdFormat(selectionModel.lastClipSpaceRay?.direction)
    }
    
    var unrotatedWorldSpaceRayOriginText: String {
        return simdFormat(selectionModel.lastUnrotatedWorldSpaceRay?.origin)
    }
    var unrotatedWorldSpaceRayDirectionText: String {
        return simdFormat(selectionModel.lastUnrotatedWorldSpaceRay?.direction)
    }
    
    var worldSpaceRayOriginText: String {
        return simdFormat(selectionModel.lastWorldSpaceRay?.origin)
    }
    var worldSpaceRayDirectionText: String {
        return simdFormat(selectionModel.lastWorldSpaceRay?.direction)
    }
    
    var body: some View {
        VStack {
            Divider()
            HStack(spacing: .zero) {
                Text("Did hit?: ")
                    .font(.caption)
                Spacer()
                Text(selectionModel.didHit ? "YES" : "NO")
                    .font(.caption)
                    .monospaced()
            }
            Divider()
            HStack(spacing: .zero) {
                Text("Element hit: ")
                    .font(.caption)
                Spacer()
                Text(selectionModel.elementHit?.name ?? "-")
                    .font(.caption)
                    .monospaced()
            }
            
            HStack(spacing: .zero) {
                Text("Screen space hit point: ")
                    .font(.caption)
                Spacer()
                Text(screenSpaceText)
                    .font(.caption)
                    .monospaced()
            }
            Divider()
            HStack(spacing: .zero) {
                Text("Clip space hit point: ")
                    .font(.caption)
                Spacer()
                Text(clipSpacePointText)
                    .font(.caption)
                    .monospaced()
            }
            Divider()
            HStack(spacing: .zero) {
                Text("Clip space ray: ")
                    .font(.caption)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(clipSpaceRayOriginText)
                        .font(.caption)
                        .monospaced()
                    Text(clipSpaceRayDirectionText)
                        .font(.caption)
                        .monospaced()
                }
            }
            Divider()
            HStack(spacing: .zero) {
                Text("(Unrotated) world space ray: ")
                    .font(.caption)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(unrotatedWorldSpaceRayOriginText)
                        .font(.caption)
                        .monospaced()
                    Text(unrotatedWorldSpaceRayDirectionText)
                        .font(.caption)
                        .monospaced()
                }
            }
            Divider()
            HStack(spacing: .zero) {
                Text("World space ray: ")
                    .font(.caption)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(worldSpaceRayOriginText)
                        .font(.caption)
                        .monospaced()
                    Text(worldSpaceRayDirectionText)
                        .font(.caption)
                        .monospaced()
                }
            }
        }
    }
    
    // MARK: - simd_float3 format
    
    func simdFormat(_ value: simd_float3?) -> String {
        guard let value else { return "-" }
        let xString = numberFormatter.string(from: NSNumber(floatLiteral: Double(value.x))) ?? "??"
        let yString = numberFormatter.string(from: NSNumber(floatLiteral: Double(value.y))) ?? "??"
        let zString = numberFormatter.string(from: NSNumber(floatLiteral: Double(value.z))) ?? "??"
        
        return "(\(xString), \(yString), \(zString))"
    }
}

#Preview {
    SelectedDebugView()
}
