//
//  WidgetSizeProbe.swift
//  WidgetSizeProbe
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI
import WidgetKit

struct ProbeEntry: TimelineEntry {
    let date: Date
    let family: String
    let displaySize: CGSize
}

struct ProbeProvider: TimelineProvider {
    func entry(for context: Context, stage: String) -> ProbeEntry {
        /// Only Sendable values are pulled from the context so nothing actor isolated is captured.
        let family = context.family.description
        let displaySize = context.displaySize
        ProbeLog.emit(family: family, displaySize: displaySize, isPreview: context.isPreview, stage: stage)
        return ProbeEntry(date: .now, family: family, displaySize: displaySize)
    }

    func placeholder(in context: Context) -> ProbeEntry {
        entry(for: context, stage: "placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ProbeEntry) -> Void) {
        completion(entry(for: context, stage: "snapshot"))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ProbeEntry>) -> Void) {
        completion(Timeline(entries: [entry(for: context, stage: "timeline")], policy: .never))
    }
}

/// Measures the frame the widget body is laid out in.
///
/// A `Shape` is used rather than `onAppear` because widget bodies are rendered as static snapshots where appearance callbacks are not guaranteed to run, while `path(in:)` is always called during rendering.
struct FrameProbe: Shape {
    let family: String
    let renderingMode: String
    let showsContainerBackground: Bool

    func path(in rect: CGRect) -> Path {
        ProbeLog.emit(
            family: family,
            viewSize: rect.size,
            renderingMode: renderingMode,
            showsContainerBackground: showsContainerBackground
        )
        return Path(rect)
    }
}

struct ProbeEntryView: View {
    let entry: ProbeEntry
    /// Identifies where the widget is being drawn. The Lock Screen renders vibrant and without a container background.
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    func sizeString(_ size: CGSize) -> String {
        String(format: "%g", size.width) + "×" + String(format: "%g", size.height)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(entry.family)
            Text(sizeString(entry.displaySize))
                .fontWeight(.bold)
        }
        .font(.system(size: 11, design: .monospaced))
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        /// Measures the full widget frame rather than the space the text happens to occupy.
        .background(
            FrameProbe(
                family: entry.family,
                renderingMode: widgetRenderingMode.description,
                showsContainerBackground: showsWidgetContainerBackground
            )
            .fill(Color.clear)
        )
        .probeContainerBackground()
    }
}

struct WidgetSizeProbe: Widget {
    let kind = "WidgetSizeProbe"

    /// Families measured by this probe.
    ///
    /// Every family the OS might offer. The accessory families are what the Lock Screen shows, so they have to be declared for the widget to appear there at all. `systemExtraLarge` is offered only on iPad and `extraLargePortrait` only from iOS 27, and WidgetKit ignores a family the current device does not support.
    var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge
        ]
        /// The accessory families are Lock Screen and watch only, and macOS has no Lock Screen.
        #if !os(macOS)
        families += [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
        if #available(iOS 27, macOS 27, *) {
            families.append(.systemExtraLargePortrait)
        }
        return families
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProbeProvider()) { entry in
            ProbeEntryView(entry: entry)
        }
        .configurationDisplayName("Widget Size Probe")
        .description("Reports the frame size WidgetKit provides for each widget family.")
        .supportedFamilies(supportedFamilies)
        /// Content margins would inset the rendered body, making the measured view size smaller than the frame. Disabling them means view size and display size should match.
        .contentMarginsDisabled()
    }
}

extension View {
    @ViewBuilder
    func probeContainerBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            self
        }
    }
}
