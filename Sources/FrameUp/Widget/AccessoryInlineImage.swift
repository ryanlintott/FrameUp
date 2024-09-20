//
//  AccessoryInlineImage.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-09-05.
//

#if os(iOS)
import SwiftUI

/// An image that will be scaled and have the rendering mode adjusted to work inside an `accessoryInline` widget.
///
/// Use inside a Label's icon property.
///
/// ```swift
/// Label {
///     Text("Label Text")
/// } icon: {
///     AccessoryInlineImage("myImage")
/// }
/// ```
///
@available(iOSApplicationExtension 16.0, *)
public struct AccessoryInlineImage: View {
    public let uiImage: UIImage
    
    /// Creates an image that will be scaled and have the rendering mode adjusted to work inside an `accessoryInline` widget.
    /// - Parameter uiImage: Base image to use.
    public init?(_ uiImage: UIImage) {
        if uiImage.isSymbolImage {
            self.uiImage = uiImage.withRenderingMode(.alwaysTemplate)
        } else {
            let widgetSize = WidgetSize.accessoryInline
            let imageSize = widgetSize.sizeForCurrentDevice(iPadTarget: .designCanvas) ?? widgetSize.minimumSize
            
            guard let uiImage = uiImage
                .scaledToFit(imageSize)?
                .withRenderingMode(.alwaysTemplate)
            else { return nil }
            self.uiImage = uiImage
        }
    }
    
    public var body: Image {
        Image(uiImage: uiImage)
    }
}

public extension AccessoryInlineImage {
    /// Creates an image that will be scaled and have the rendering mode adjusted to work inside an `accessoryInline` widget.
    /// - Parameter name: The name of the image asset or file.
    /// - Parameter bundle: The bundle containing the image file or asset catalog. Specify nil to search the app’s main bundle.
    init?(_ name: String, bundle: Bundle? = nil) {
        guard let uiImage = UIImage(named: name, in: bundle, with: nil) else { return nil }
        self.init(uiImage)
    }
}
#endif
