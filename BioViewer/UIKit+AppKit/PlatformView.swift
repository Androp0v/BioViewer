//
//  PlatformView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/6/24.
//

#if os(iOS)
import UIKit
typealias PlatformView = UIView
typealias PlatformViewController = UIViewController
#elseif os(macOS)
import AppKit
typealias PlatformView = NSView
typealias PlatformViewController = NSViewController
#endif
