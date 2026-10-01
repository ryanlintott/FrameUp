//
//  WidgetFrames+Unavailable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-01.
//

import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// The widget tools that shipped in FrameUp 0.9.11 moved to the WidgetFrames package in FrameUp 1.0.0.
///
/// Each one is kept here as an unavailable stub so code written against 0.9.11 fails to compile with a message naming its replacement, rather than with an unknown symbol. None of them can be called, so their bodies are never run.

@available(*, unavailable, message: "WidgetSize moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public enum WidgetSize: String, Identifiable, CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    case accessoryCircular
    case accessoryRectangular
    case accessoryInline

    public var id: String { fatalError() }
}

@available(*, unavailable, message: "Use canvasSize and renderedSize on WidgetFrame from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public enum WidgetTarget {
    case designCanvas, homeScreen
}

@available(*, unavailable)
public extension WidgetSize {
    @available(*, unavailable, message: "Use CGSize.")
    typealias Size = (CGFloat, CGFloat)

    @available(*, unavailable, message: "Use WidgetSize.frames(platform: .phone, screenSize:) from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static func sizesForiPhone(screenSize: CGSize) -> [WidgetSize: CGSize] { fatalError() }

    @available(*, unavailable, message: "Use WidgetSize.frames(platform: .pad, screenSize:) from the WidgetFrames package and read canvasSize or renderedSize: https://github.com/ryanlintott/WidgetFrames")
    static func sizesForiPad(screenSize: CGSize, target: WidgetTarget) -> [WidgetSize: CGSize] { fatalError() }

    @available(*, unavailable, message: "Use WidgetSize.frames(platform: .watch, screenSize:) from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static func sizesForWatch(watchSize: CGFloat) -> [WidgetSize: CGSize] { fatalError() }

    @available(*, unavailable, message: "Use minimumSize from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    var minimumSize: CGSize { fatalError() }

    @available(*, unavailable, message: "Use maximumSize from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    var maximumSize: CGSize { fatalError() }

    @available(*, unavailable, message: "Use frame(platform: .phone, screenSize:)?.canvasSize from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    func sizeForiPhone(screenSize: CGSize) -> CGSize? { fatalError() }

    @available(*, unavailable, message: "Use frame(platform: .pad, screenSize:) from the WidgetFrames package and read canvasSize or renderedSize: https://github.com/ryanlintott/WidgetFrames")
    func sizeForiPad(screenSize: CGSize, target: WidgetTarget) -> CGSize? { fatalError() }

    @available(*, unavailable, message: "Use frame(platform: .watch, screenSize:)?.canvasSize from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    func sizeForWatch(watchSize: CGFloat) -> CGSize? { fatalError() }

    @available(*, unavailable, message: "Use frame(platform: .pad, screenSize:)?.scaleFactor from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    func scaleFactorForiPad(screenSize: CGSize) -> CGFloat? { fatalError() }
}

#if os(iOS)
@available(*, unavailable)
public extension WidgetSize {
    @available(*, unavailable, message: "Use WidgetSize.supportedSizes(platform:) from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static func supportedSizes(for device: UIUserInterfaceIdiom) -> [WidgetSize] { fatalError() }

    @available(*, unavailable, message: "Use supportedSizesForCurrentDevice from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static var supportedSizesForCurrentDevice: [WidgetSize] { fatalError() }

    @available(*, unavailable, message: "Use frameForCurrentDevice() from the WidgetFrames package and read canvasSize or renderedSize: https://github.com/ryanlintott/WidgetFrames")
    func sizeForCurrentDevice(iPadTarget: WidgetTarget) -> CGSize? { fatalError() }

    @available(*, unavailable, message: "Use frameForCurrentDevice()?.scaleFactor from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    var scaleFactorForCurrentDevice: CGFloat? { fatalError() }
}
#endif

#if canImport(WidgetKit)
@available(*, unavailable)
public extension WidgetSize {
    @available(*, unavailable, message: "Use widgetFamily from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    var widgetFamily: WidgetFamily? { fatalError() }
}

@available(*, unavailable)
public extension WidgetFamily {
    #if os(iOS)
    @available(*, unavailable, message: "Use WidgetFamily.supportedFamiliesForCurrentDevice from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static var supportedFamiliesForCurrentDevice: [WidgetFamily] { fatalError() }
    #endif

    @available(*, unavailable, message: "Use WidgetFamily.size from the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    var size: WidgetSize? { fatalError() }
}
#endif

@available(*, unavailable, message: "WidgetDemoFrame moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public struct WidgetDemoFrame<Content: View>: View {
    public typealias SizeAndCornerRadius = (CGSize, CGFloat) -> Content

    @available(*, unavailable, message: "WidgetDemoFrame moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    public init(widgetSize: WidgetSize, designCanvasSize: CGSize, homeScreenSize: CGSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) { fatalError() }

    public var body: some View { EmptyView() }
}

@available(*, unavailable)
public extension WidgetDemoFrame {
    @available(*, unavailable, message: "WidgetDemoFrame moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    static func minimumSize(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) -> Self { fatalError() }
}

#if os(iOS)
@available(*, unavailable)
public extension WidgetDemoFrame {
    @available(*, unavailable, message: "WidgetDemoFrame moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    init?(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) { fatalError() }
}

@available(*, unavailable, message: "AccessoryInlineImage moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public struct AccessoryInlineImage: View {
    public let uiImage: UIImage

    @available(*, unavailable, message: "AccessoryInlineImage moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    public init?(_ uiImage: UIImage) { fatalError() }

    public var body: Image { Image(uiImage: uiImage) }
}

@available(*, unavailable)
public extension AccessoryInlineImage {
    @available(*, unavailable, message: "AccessoryInlineImage moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    init?(_ name: String, bundle: Bundle? = nil) { fatalError() }
}

@available(*, unavailable, message: "ScaledContainerRelativeShape moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public struct ScaledContainerRelativeShape: Shape {
    public func path(in rect: CGRect) -> Path { fatalError() }
}

@available(*, unavailable, message: "WidgetRelativeShape moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
public typealias WidgetRelativeShape = ScaledShape<ScaledContainerRelativeShape>

@available(*, unavailable)
public extension ScaledShape where Content == ScaledContainerRelativeShape {
    @available(*, unavailable, message: "WidgetRelativeShape moved to the WidgetFrames package: https://github.com/ryanlintott/WidgetFrames")
    init(_ widgetFamily: WidgetFamily) { fatalError() }
}
#endif
