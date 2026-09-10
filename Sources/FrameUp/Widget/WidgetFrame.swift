//
//  WidgetFrame.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

/// The frame one widget size takes in one place on one device.
///
/// A widget is laid out on a design canvas and then drawn. On every platform but the iPad Home Screen those are the same size, so ``canvasSize`` is the one to use unless you want to scale an iPad widget to display at its Home Screen size.
///
/// Obtained from ``WidgetSize/frame(platform:screenSize:majorOSVersion:displayScale:placement:)`` for a specified device, or `frameForCurrentDevice()` for the one the code is running on.
public struct WidgetFrame: Sendable, Equatable {
    /// The size widget content is laid out in.
    ///
    /// This is the size a widget's `body` is given, and the size to design against.
    public let canvasSize: CGSize

    /// The size the widget is drawn at on screen.
    ///
    /// Equal to ``canvasSize`` everywhere except the iPad Home Screen, which scales the canvas down into the slot its grid gives the widget. An iPad Lock Screen widget is not scaled, so its two sizes match like every other platform's.
    public let renderedSize: CGSize

    /// Creates a widget frame.
    /// - Parameters:
    ///   - canvasSize: The size widget content is laid out in.
    ///   - renderedSize: The size the widget is drawn at. Defaults to `canvasSize`, which is correct everywhere but the iPad Home Screen.
    public init(canvasSize: CGSize, renderedSize: CGSize? = nil) {
        self.canvasSize = canvasSize
        self.renderedSize = renderedSize ?? canvasSize
    }

    /// How much the widget is scaled to fit where it is drawn.
    ///
    /// ``renderedSize`` width divided by ``canvasSize`` width. 1 everywhere except the iPad Home Screen, where it ranges from 0.849 to 1 depending on the iPad.
    public var scaleFactor: CGFloat {
        guard canvasSize.width > 0 else { return 1 }
        return renderedSize.width / canvasSize.width
    }
}
