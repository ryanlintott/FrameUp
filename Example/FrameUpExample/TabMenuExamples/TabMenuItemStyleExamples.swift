//
//  TabMenuItemStyleExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-09.
//

import FrameUp
import SwiftUI

#if os(iOS)
/// Shows icons only in a vertical bar, and the icon and title side by side along the bottom, with a capsule behind the selected item.
@available(iOS 16, *)
struct CapsuleItemStyle: TabMenuItemStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if configuration.axis == .vertical {
                configuration.label
                    .labelStyle(.iconOnly)
            } else {
                configuration.label
                    .labelStyle(.titleAndIcon)
            }
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(configuration.isSelected ? .white : .secondary)
        .background {
            if configuration.isSelected {
                Capsule().fill(.tint)
            }
        }
    }
}

/// Stacks a large icon over a small title.
@available(iOS 16, *)
struct StackedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 2) {
            configuration.icon
                .imageScale(.large)
                .frame(height: 24)
            configuration.title
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

/// Stacks a large icon over a small title, with a dot beside the selected item, on the side nearest the content.
@available(iOS 16, *)
struct DotItemStyle: TabMenuItemStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(StackedLabelStyle())
            .foregroundStyle(configuration.isSelected ? .primary : .secondary)
            .overlay(alignment: dotAlignment(for: configuration.edge)) {
                if configuration.isSelected {
                    Circle()
                        .fill(.tint)
                        .frame(width: 5, height: 5)
                        .padding(2)
                }
            }
    }

    /// Above the item along the bottom, toward the middle of the screen in a vertical bar.
    private func dotAlignment(for edge: Edge?) -> Alignment {
        switch edge {
        case .leading: .trailing
        case .trailing: .leading
        default: .top
        }
    }
}

/// The item styles the examples can switch between.
@available(iOS 16, *)
enum ExampleTabMenuItemStyleChoice: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case gradient = "Gradient"
    case capsule = "Capsule"
    case dot = "Dot"

    var id: Self { self }
}

/// Draws items with the chosen style, so switching styles doesn't change the structure of the view the style is applied to.
@available(iOS 16, *)
struct ExampleTabMenuItemStyle: TabMenuItemStyle {
    let choice: ExampleTabMenuItemStyleChoice

    func makeBody(configuration: Configuration) -> some View {
        switch choice {
        case .automatic:
            AutomaticTabMenuItemStyle().makeBody(configuration: configuration)
        case .gradient:
            MaskedTabMenuItemStyle.masked { isSelected in
                TabMenuExample.gradientFill(isSelected: isSelected)
            }
            .makeBody(configuration: configuration)
        case .capsule:
            CapsuleItemStyle().makeBody(configuration: configuration)
        case .dot:
            DotItemStyle().makeBody(configuration: configuration)
        }
    }
}
#endif
