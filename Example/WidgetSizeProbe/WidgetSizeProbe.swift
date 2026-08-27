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
    let widgetKind: String
    let displaySize: CGSize
}

struct ProbeProvider: TimelineProvider {
    let widgetKind: String

    func entry(for context: Context, stage: String) -> ProbeEntry {
        /// Only Sendable values are pulled from the context so nothing actor isolated is captured.
        let family = context.family.description
        let displaySize = context.displaySize
        ProbeLog.emit(family: family, widgetKind: widgetKind, displaySize: displaySize, isPreview: context.isPreview, stage: stage)
        return ProbeEntry(date: .now, family: family, widgetKind: widgetKind, displaySize: displaySize)
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
    let widgetKind: String
    let renderingMode: String
    let showsContainerBackground: Bool
    let showsWidgetLabel: Bool?

    func path(in rect: CGRect) -> Path {
        ProbeLog.emit(
            family: family,
            widgetKind: widgetKind,
            viewSize: rect.size,
            renderingMode: renderingMode,
            showsContainerBackground: showsContainerBackground,
            showsWidgetLabel: showsWidgetLabel
        )
        return Path(rect)
    }
}

struct ProbeEntryView: View {
    let entry: ProbeEntry
    /// Identifies where the widget is being drawn. The Lock Screen renders vibrant and without a container background.
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    /// On watchOS this separates a watch face complication, which shows a widget label, from the Smart Stack, which does not. macOS has no such environment value.
    #if !os(macOS)
    @Environment(\.showsWidgetLabel) private var widgetLabelShown
    #endif

    /// Nil on macOS, where `showsWidgetLabel` does not exist.
    var showsWidgetLabel: Bool? {
        #if os(macOS)
        nil
        #else
        widgetLabelShown
        #endif
    }

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
        /// Readable against ``probeFill``.
        .foregroundStyle(.black)
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        /// Measures the full widget frame rather than the space the text happens to occupy.
        .background(
            FrameProbe(
                family: entry.family,
                widgetKind: entry.widgetKind,
                renderingMode: widgetRenderingMode.description,
                showsContainerBackground: showsWidgetContainerBackground,
                showsWidgetLabel: showsWidgetLabel
            )
            /// Opaque white rather than clear so the frame is visible in a screenshot wherever the container background is not drawn.
            ///
            /// The Lock Screen removes the container background and renders vibrant, which turns ``Color/probeFill`` into a material keyed on luminance. White is the brightest that mode can produce, so a full bleed white fill is the one marking that survives it. Content margins are disabled, so this shape is exactly the widget frame.
            .fill(.white)
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
        /// watchOS has no system families at all. `accessoryCorner` exists only here, and is included even though `WidgetSize` has no case for it, because measuring it costs nothing and the frame is otherwise unrecorded anywhere.
        #if os(watchOS)
        return [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
        #else
        var families: [WidgetFamily] = [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge
        ]
        /// The accessory families appear on the Lock Screen and, from visionOS 27, on Vision Pro. macOS has no Lock Screen, and the visionOS SDK has no `accessoryInline` case at all.
        #if os(visionOS)
        if #available(visionOS 27, *) {
            families += [.accessoryCircular, .accessoryRectangular]
        }
        #elseif !os(macOS)
        families += [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
        /// `systemExtraLargePortrait` arrived in visionOS 26, a release earlier than on iOS and macOS.
        if #available(iOS 27, macOS 27, visionOS 26, *) {
            families.append(.systemExtraLargePortrait)
        }
        return families
        #endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProbeProvider(widgetKind: kind)) { entry in
            ProbeEntryView(entry: entry)
        }
        .configurationDisplayName("Widget Size Probe")
        .description("Reports the frame size WidgetKit provides for each widget family.")
        .supportedFamilies(supportedFamilies)
        /// Content margins would inset the rendered body, making the measured view size smaller than the frame. Disabling them means view size and display size should match.
        .contentMarginsDisabled()
    }
}

#if os(watchOS)
/// Families a placement probe offers. Every family watchOS has, so nothing is missed by the split.
@available(watchOS 26.0, *)
private let placementProbeFamilies: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]

/// Builds a probe that is disfavoured in one of the two places a watchOS widget can appear.
///
/// Every watchOS family reports two frames and nothing readable at render time says which place a render came from. `WidgetLocation` only goes into `disfavoredLocations`, and `showsWidgetLabel` was tried and does not separate them: both frames appear with it true and false.
///
/// So the location is varied on the way in instead. One probe disfavours the watch face and the other disfavours the Smart Stack, and the frames each reports attribute a size to a place. Disfavouring is a preference rather than an exclusion, so a frame that still appears under both probes means the split failed rather than that the two places agree.
@available(watchOS 26.0, *)
@MainActor
private func placementProbe(kind: String, disfavored: WidgetLocation) -> some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ProbeProvider(widgetKind: kind)) { entry in
        ProbeEntryView(entry: entry)
    }
    .configurationDisplayName(kind)
    .description("Reports frames for a widget disfavoured in one location.")
    .supportedFamilies(placementProbeFamilies)
    .contentMarginsDisabled()
    .disfavoredLocations([disfavored], for: placementProbeFamilies)
}

/// Prefers the Smart Stack by disfavouring the watch face.
@available(watchOS 26.0, *)
struct SmartStackProbe: Widget {
    var body: some WidgetConfiguration {
        placementProbe(kind: "SmartStackProbe", disfavored: .watchFace)
    }
}

/// Prefers the watch face by disfavouring the Smart Stack.
@available(watchOS 26.0, *)
struct WatchFaceProbe: Widget {
    var body: some WidgetConfiguration {
        placementProbe(kind: "WatchFaceProbe", disfavored: .smartStack)
    }
}
#endif

extension Color {
    /// Fill used for the widget's container background.
    ///
    /// A saturated colour nothing else on a Home Screen or Lock Screen uses, so a placed widget's bounds can be found in a screenshot by testing pixels rather than by eye. Measuring a placed widget is the only way to get an iPad's Home Screen frame, since `displaySize` there reports the design canvas.
    ///
    /// The system desaturates this in the accented and vibrant rendering modes, so a measurement run wants the widget rendered in full colour.
    static var probeFill: Color {
        Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)
    }
}

extension View {
    @ViewBuilder
    func probeContainerBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
            containerBackground(Color.probeFill, for: .widget)
        } else {
            self
        }
    }
}
