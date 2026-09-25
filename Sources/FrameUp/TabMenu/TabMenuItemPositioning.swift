//
//  TabMenuItemPositioning.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// How a horizontal ``TabMenu`` spreads its items across its width.
///
/// A vertical menu, in the system's vertical bar on the iPhone Duo, always stacks its items in the bar and ignores this.
public enum TabMenuItemPositioning: Hashable, Sendable {
    /// Items share the menu's full width equally, like the iPhone tab bar in iOS 15–18.
    case fill
    /// Items are at most `maxItemWidth` wide, `spacing` apart, and centred as a group. When there isn't room, they shrink equally to fit.
    case centered(maxItemWidth: CGFloat, spacing: CGFloat = 0)
}
#endif
