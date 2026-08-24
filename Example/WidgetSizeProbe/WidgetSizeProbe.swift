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

    func path(in rect: CGRect) -> Path {
        ProbeLog.emit(family: family, viewSize: rect.size)
        return Path(rect)
    }
}

struct ProbeEntryView: View {
    let entry: ProbeEntry

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
        .background(FrameProbe(family: entry.family).fill(Color.clear))
        .probeContainerBackground()
    }
}

struct WidgetSizeProbe: Widget {
    let kind = "WidgetSizeProbe"

    /// Families measured by this probe.
    ///
    /// Only the Home Screen system families so far. These already have known frames in `WidgetSize`, so they can be used to validate the method against published values before measuring families that have no published frame.
    var supportedFamilies: [WidgetFamily] {
        [.systemSmall, .systemMedium, .systemLarge]
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
        if #available(iOS 17.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            self
        }
    }
}
