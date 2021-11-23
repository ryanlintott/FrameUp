//
//  FixWidgetPreviewAlignmentBug.swift
//  
//
//  Created by Ryan Lintott on 2021-11-23.
//

import SwiftUI
import WidgetKit

/// Not working yet!
/// Attempts to fix the widget preview alignment bug
/// Alignment offset is different on different iPads and doesn't correspond to any variables I've tried to link it to.
/// .top, .center and .bottom are all offset by the same amount
struct FixWidgetPreviewAlignmentBug: ViewModifier {
    @Environment(\.widgetFamily) var widgetFamily
    
    let adjustment: CGFloat
    
    var smartAdjustment: CGFloat {
        // use a fixed size as it seems to be the same misalignment on all sizes
        let designHeight = WidgetSize.large.sizeForCurrentDevice(iPadTarget: .designCanvas).height
        let screenHeight = UIScreen.main.fixedCoordinateSpace.bounds.height

        return 1 - (designHeight / screenHeight)
    }
    
    // iPad (9th generation) - offset: 11.5
    // screen: 1081, design: 320.5, home: 272, scale: 0.848, 1 - (designHeight / screenHeight): 0.703
    
    // iPad Pro (12.9-inch) (5th generation) - offset: 12.5
    // screen 1366, design: 378.5, home: 356, scale: 0.941, 1 - (designHeight / screenHeight): 0.723
    
    // iPad Mini (5th generation) - offset: 14
    // screen: 1133, design: 305.5, home: 260, scale: 0.851, 1 - (designHeight / screenHeight): 0.730
    
    func body(content: Content) -> some View {
        content
//            .overlay(
//                Text("\(smartAdjustment)")
//                    .foregroundColor(.red)
//                , alignment: .bottom
//            )
            .alignmentGuide(VerticalAlignment.center) { d in
                guard UIDevice.current.userInterfaceIdiom == .pad else {
                    return d[VerticalAlignment.center]
                }
                
                return d[VerticalAlignment.center] + adjustment
            }
            
    }
}

@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
public extension View {
    /// Only for use in Widget Previews. Adjustment is manual and may not be 100% accurate
    /// - Returns: View adjusted vertically to fit within the widget cropped area.
    func fixWidgetPreviewAlignmentBug(adjustment: CGFloat) -> some View {
        self.modifier(FixWidgetPreviewAlignmentBug(adjustment: adjustment))
    }
}
