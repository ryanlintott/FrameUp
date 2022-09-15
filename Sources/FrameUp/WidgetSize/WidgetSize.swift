//
//  WidgetSize.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-17.
//

import SwiftUI

/// A template with similar elements to WidgetFamily that can be used without importing WidgetKit
///
/// Used to specify widget sizes for preview purposes inside an app.
public enum WidgetSize: String, Identifiable {
    case small
    case medium
    case large
    case extraLarge
//    case accessoryCircular
//    case accessoryRectangular
//    case accessoryInline
    
    public var id: String {
        self.rawValue
    }
}

/// iPad widget frame target.
///
/// iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit. This parameter can be used to specify which size you want.
public enum WidgetTarget {
    case designCanvas, homeScreen
}

public extension WidgetSize {
    /// Smallest widget size possibe for each WidgetFamily
    static let minimumSizes: [WidgetSize: CGSize] = [
            .small: CGSize(width: 141, height: 141),
            .medium: CGSize(width: 292, height: 141),
            .large: CGSize(width: 292, height: 311),
            .extraLarge: CGSize(width: 540, height: 260)
        ]
    
    /// Widget sizes for iPhone
    /// - Parameter screenSize: iPhone screen size ignoring orientation.
    /// - Returns: A dictionary of sizes based on widget size.
    static func sizesForiPhone(screenSize: CGSize) -> [WidgetSize: CGSize] {
        let widgetSizes: ((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))
        
        /// source: https://developer.apple.com/design/human-interface-guidelines/widgets/overview/design/
        switch (screenSize.width, screenSize.height) {
        case (428..., 926...):
            widgetSizes = ((170, 170), (364, 170), (364, 382))
        case (414..., 896...):
            widgetSizes = ((169, 169), (360, 169), (360, 379))
        case (414..., 736...):
            widgetSizes = ((159, 159), (348, 157), (348, 357))
        case (390..., 844...):
            widgetSizes = ((158, 158), (338, 158), (338, 354))
        case (375..., 812...):
            widgetSizes = ((155, 155), (329, 155), (329, 345))
        case (375..., 667...):
            widgetSizes = ((148, 148), (321, 148), (321, 324))
        case (360..., 780...):
            widgetSizes = ((155, 155), (329, 155), (329, 345))
        case (320..., 568...):
            widgetSizes = ((141, 141), (292, 141), (292, 311))
        default:
            widgetSizes = ((141, 141), (292, 141), (292, 311))
        }
        
        return [
            .small: CGSize(width: widgetSizes.0.0, height: widgetSizes.0.1),
            .medium: CGSize(width: widgetSizes.1.0, height: widgetSizes.1.1),
            .large: CGSize(width: widgetSizes.2.0, height: widgetSizes.2.1)
        ]
    }

    /// Widget sizes for iPad
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: A dictionary of sizes based on widget size.
    static func sizesForiPad(screenSize: CGSize, target: WidgetTarget) -> [WidgetSize: CGSize] {
        let widgetSizes: ((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))
        
        /// source: https://developer.apple.com/design/human-interface-guidelines/widgets/overview/design/
        switch target {
        case .designCanvas:
            switch (screenSize.width, screenSize.height) {
            case (1192..., 1590...):
                widgetSizes = ((188, 188), (412, 188), (412, 412), (860, 412))
            case (1024..., 1366...):
                widgetSizes = ((170, 170), (378.5, 170), (378.5, 378.5), (795, 378.5))
            case (970..., 1389...):
                widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
            case (954..., 1373...):
                widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
            case (834..., 1194...):
                widgetSizes = ((155, 155), (342, 155), (342, 342), (715.5, 342))
            case (834..., 1112...):
                widgetSizes = ((150, 150), (327.5, 150), (327.5, 327.5), (682, 327.5))
            case (820..., 1180...):
                widgetSizes = ((155, 155), (342, 155), (342, 342), (715.5, 342))
            case (810..., 1080...):
                widgetSizes = ((146, 146), (320.5, 146), (320.5, 320.5), (669, 320.5))
            case (744..., 1033...):
                widgetSizes = ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5))
            case (768..., 1024...):
                widgetSizes = ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5))
            default:
                widgetSizes = ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5))
            }
        case .homeScreen:
            switch (screenSize.width, screenSize.height) {
            case (1192..., 1590...):
                widgetSizes = ((188, 188), (412, 188), (412, 412), (860, 412))
            case (1024..., 1366...):
                widgetSizes = ((160, 160), (356, 160), (356, 356), (748, 356))
            case (970..., 1389...):
                widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
            case (954..., 1373...):
                widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
            case (834..., 1194...):
                widgetSizes = ((136, 136), (300, 136), (300, 300), (628, 300))
            case (834..., 1112...):
                widgetSizes = ((132, 132), (288, 132), (288, 288), (600, 288))
            case (820..., 1180...):
                widgetSizes = ((136, 136), (300, 136), (300, 300), (628, 300))
            case (810..., 1080...):
                widgetSizes = ((124, 124), (272, 124), (272, 272), (568, 272))
            case (744..., 1033...):
                widgetSizes = ((120, 120), (260, 120), (260, 260), (540, 260))
            case (768..., 1024...):
                widgetSizes = ((120, 120), (260, 120), (260, 260), (540, 260))
            default:
                widgetSizes = ((120, 120), (260, 120), (260, 260), (540, 260))
            }
        }
        
        return [
            .small: CGSize(width: widgetSizes.0.0, height: widgetSizes.0.1),
            .medium: CGSize(width: widgetSizes.1.0, height: widgetSizes.1.1),
            .large: CGSize(width: widgetSizes.2.0, height: widgetSizes.2.1),
            .extraLarge: CGSize(width: widgetSizes.3.0, height: widgetSizes.3.1)
        ]
    }
    
    /// Smallest size for this widget size.
    var minimumSize: CGSize {
        Self.minimumSizes[self] ?? .zero
    }
    
    /// Size for this widget on an iPhone with the specified screen size.
    /// - Parameter screenSize: iPhone screen size ignoring orientation.
    /// - Returns: Size for this widget. Zero if widget size is not available.
    func sizeForiPhone(screenSize: CGSize) -> CGSize {
        Self.sizesForiPhone(screenSize: screenSize)[self] ?? .zero
    }
    
    /// Size for this widget on an iPad with the specified screen size.
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget. Zero if widget size is not available.
    func sizeForiPad(screenSize: CGSize, target: WidgetTarget) -> CGSize {
        Self.sizesForiPad(screenSize: screenSize, target: target)[self] ?? .zero
    }

}

