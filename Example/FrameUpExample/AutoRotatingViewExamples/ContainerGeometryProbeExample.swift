//
//  ContainerGeometryProbeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-25.
//

import FrameUp
import os
import SwiftUI

#if os(iOS)
private let logger = Logger(subsystem: "com.abetterwaytodo.FrameUpExample", category: "ContainerGeometryProbe")

/// Shows the container geometry SwiftUI reports to a full-size view, both directly and inside a portrait-only `AutoRotatingView`.
///
/// Every change is also written to the unified log, prefixed with where it was read:
/// `xcrun simctl spawn booted log stream --level info --predicate 'category == "ContainerGeometryProbe"'`
struct ContainerGeometryProbeExample: View {
    @State private var isInsideAutoRotatingView = false
    /// The only orientation the inside view allows. Anything but the device's orientation makes it rotate its content.
    @State private var allowedOrientation: FUInterfaceOrientation = .portrait
    
    var body: some View {
        ContainerGeometryReadout(location: "outside")
            .overlay(alignment: .bottom) {
                Button("Show inside an AutoRotatingView") {
                    isInsideAutoRotatingView = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 60)
            }
            .navigationTitle("Container Geometry")
            .fullScreenCover(isPresented: $isInsideAutoRotatingView) {
                AutoRotatingView([allowedOrientation]) { geometry in
                    ContainerGeometryReadout(location: "inside \(allowedOrientation)", geometry: geometry)
                }
                .overlay(alignment: .bottom) {
                    /// Outside the rotation, so it stays with the interface.
                    VStack {
                        Picker("Allowed orientation", selection: $allowedOrientation) {
                            Text("Portrait").tag(FUInterfaceOrientation.portrait)
                            Text("Left").tag(FUInterfaceOrientation.landscapeLeft)
                            Text("Right").tag(FUInterfaceOrientation.landscapeRight)
                            Text("Upside down").tag(FUInterfaceOrientation.portraitUpsideDown)
                        }
                        .pickerStyle(.segmented)
                        
                        Button("Close") {
                            isInsideAutoRotatingView = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 60)
                }
            }
    }
}

/// Draws the container geometry a full-size reader sees: the container shape (purple), reserved regions (red for occlusion, orange for division, dashed when inactive), container corner insets (blue), and a label moved by `containerCornerOffset`.
private struct ContainerGeometryReadout: View {
    /// Where the values are read, for the log.
    let location: String
    /// The geometry from an `AutoRotatingView`, when inside one.
    var geometry: AutoRotatingGeometry? = nil
    
    var body: some View {
        GeometryReader { proxy in
            let summary = "\(location) | " + Self.summary(proxy) + frameUpSummary
            ZStack(alignment: .topLeading) {
                Color.clear

                /// The container shape, which should round the corners that sit on the display's rounded ones.
                ContainerRelativeShape()
                    .strokeBorder(.purple, lineWidth: 6)

                reservedRegions(proxy)

                cornerInsets(proxy)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Container geometry")
                        .font(.headline)
                    ForEach(summary.components(separatedBy: " | "), id: \.self) { line in
                        Text(line)
                    }
                }
                .font(.caption.monospaced())
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 120)
                .padding(.horizontal, 20)

                offsetLabel

                /// Readers inset from the edges by different amounts, to measure how SwiftUI resolves corner insets for a smaller frame.
                ForEach(Self.readerInsets, id: \.short) { insets in
                    let name = "inset reader \(insets.short)"
                    GeometryReader { insetProxy in
                        Color.clear
                            .task(id: insetSummary(insetProxy)) {
                                logger.info("\(location, privacy: .public) | \(name, privacy: .public) | \(insetSummary(insetProxy), privacy: .public)")
                            }
                    }
                    .padding(insets)
                }
            }
            .task(id: summary) {
                logger.info("\(summary, privacy: .public)")
            }
        }
        .ignoresSafeArea()
    }

    /// Insets (top, leading, bottom, trailing) of the readers that compare corner insets for smaller frames: even, uneven, and past the width of the Duo's capsule but not its height.
    static let readerInsets: [EdgeInsets] = [
        EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30),
        EdgeInsets(top: 100, leading: 0, bottom: 0, trailing: 0),
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 100),
    ]

    /// The geometry's corner insets, when inside an `AutoRotatingView`.
    var frameUpSummary: String {
        #if compiler(>=6.2)
        if #available(iOS 26, *), let geometry {
            return " | frameup " + Self.corners(geometry.containerCornerInsets)
        }
        #endif
        return ""
    }

    /// SwiftUI's corner insets for a reader.
    func insetSummary(_ proxy: GeometryProxy) -> String {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            return "swiftui " + Self.corners(proxy.containerCornerInsets)
        }
        #endif
        return "needs iOS 26"
    }

    #if compiler(>=6.2)
    @available(iOS 26, *)
    static func corners(_ insets: RectangleCornerInsets) -> String {
        "corners TL=\(insets.topLeading.short) TR=\(insets.topTrailing.short) BL=\(insets.bottomLeading.short) BR=\(insets.bottomTrailing.short)"
    }
    #endif

    /// A label that `containerCornerOffset` should move clear of the top leading corner.
    @ViewBuilder
    var offsetLabel: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            Text("containerCornerOffset")
                .font(.caption.bold())
                .padding(6)
                .background(.green)
                .containerCornerOffset([.top, .leading])
        }
        #endif
    }

    @ViewBuilder
    func reservedRegions(_ proxy: GeometryProxy) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            ForEach(proxy.reservedRegions(kind: .occlusion, options: .includeInactive)) { region in
                regionOutline(region.frame, color: .red, isActive: region.isActive)
            }
            ForEach(proxy.reservedRegions(kind: .division, options: .includeInactive)) { region in
                regionOutline(region.frame, color: .orange, isActive: region.isActive)
            }
        }
        #endif
    }

    func regionOutline(_ frame: CGRect, color: Color, isActive: Bool) -> some View {
        Rectangle()
            .strokeBorder(color, style: StrokeStyle(lineWidth: 3, dash: isActive ? [] : [6]))
            .background(color.opacity(0.2))
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
    }

    @ViewBuilder
    func cornerInsets(_ proxy: GeometryProxy) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            let insets = proxy.containerCornerInsets
            let size = proxy.size
            cornerRect(insets.topLeading, origin: .zero)
            cornerRect(insets.topTrailing, origin: CGPoint(x: size.width - insets.topTrailing.width, y: 0))
            cornerRect(insets.bottomLeading, origin: CGPoint(x: 0, y: size.height - insets.bottomLeading.height))
            cornerRect(insets.bottomTrailing, origin: CGPoint(x: size.width - insets.bottomTrailing.width, y: size.height - insets.bottomTrailing.height))
        }
        #endif
    }

    func cornerRect(_ size: CGSize, origin: CGPoint) -> some View {
        Rectangle()
            .fill(.blue.opacity(0.5))
            .frame(width: size.width, height: size.height)
            .offset(x: origin.x, y: origin.y)
    }

    /// One line per value, joined with " | ".
    static func summary(_ proxy: GeometryProxy) -> String {
        var lines = ["size=\(proxy.size.width.formatted())x\(proxy.size.height.formatted())"]
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            let insets = proxy.containerCornerInsets
            lines.append("corners TL=\(insets.topLeading.short) TR=\(insets.topTrailing.short) BL=\(insets.bottomLeading.short) BR=\(insets.bottomTrailing.short)")
        }
        #endif
        #if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27.0, *) {
            if let radii = proxy.concentricCornerRadii {
                lines.append("concentric TL=\(radii.topLeading.formatted()) TR=\(radii.topTrailing.formatted()) BL=\(radii.bottomLeading.formatted()) BR=\(radii.bottomTrailing.formatted())")
            } else {
                lines.append("concentric: nil")
            }
        }
        #endif
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            for (name, kind) in [("occlusion", ReservedRegion.Kind.occlusion), ("division", .division)] {
                let regions = proxy.reservedRegions(kind: kind, options: .includeInactive, layoutDirectionBehavior: .fixed)
                lines.append("\(name): " + (regions.isEmpty ? "none" : regions.map { "\($0.frame.short)\($0.isActive ? "" : " inactive") margins=\($0.margins.short)" }.joined(separator: ", ")))
            }
        } else {
            lines.append("reserved regions: needs iOS 27.1")
        }
        #else
        lines.append("reserved regions: needs the iOS 27.1 SDK")
        #endif
        return lines.joined(separator: " | ")
    }
}

private extension CGSize {
    var short: String {
        "\(width.formatted())x\(height.formatted())"
    }
}

private extension CGRect {
    var short: String {
        "(\(minX.formatted()),\(minY.formatted()) \(width.formatted())x\(height.formatted()))"
    }
}

private extension EdgeInsets {
    var short: String {
        "\(top.formatted()),\(leading.formatted()),\(bottom.formatted()),\(trailing.formatted())"
    }
}
#endif
