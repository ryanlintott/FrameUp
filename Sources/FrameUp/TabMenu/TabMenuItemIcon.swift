//
//  TabMenuItemIcon.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// The icon of a ``TabMenuItem``, with its type erased so items with different icons can share an array. It behaves like any other view.
///
/// An image, such as an SF Symbol, is kept as given, so it responds to `font` and `imageScale` as in a system `Label`. The ``TabMenuItemStyle/masked(_:)`` style makes it resizable to draw it at its fixed height.
public struct TabMenuItemIcon: View {
    /// The icon as given: an image, kept so a style can make it resizable, or any other view.
    enum Storage {
        case image(Image)
        case view(AnyView)

        init<Icon: View>(_ icon: Icon) {
            if let image = icon as? Image {
                self = .image(image)
            } else {
                self = .view(AnyView(icon))
            }
        }
    }

    private let storage: Storage

    /// Set by a style that draws the icon at a fixed size, such as ``TabMenuItemStyle/masked(_:)``, so an image icon is resizable rather than drawn at its natural size.
    @Environment(\.tabMenuItemIconIsResizable) private var isResizable

    init(_ storage: Storage) {
        self.storage = storage
    }

    public var body: some View {
        switch storage {
        case let .image(image):
            if isResizable {
                image.resizable()
            } else {
                image
            }
        case let .view(view):
            view
        }
    }
}
#endif
