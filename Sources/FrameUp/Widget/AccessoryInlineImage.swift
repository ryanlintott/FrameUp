//
//  AccessoryInlineImage.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-09-05.
//

import SwiftUI

#if os(iOS)
@available(iOSApplicationExtension 16.0, *)
public struct AccessoryInlineImage: View {
    public let uiImage: UIImage
    
    public init?(_ name: String, bundle: Bundle? = nil, renderingMode: UIImage.RenderingMode = .alwaysTemplate) {
        let widgetSize = WidgetSize.accessoryInline
        let imageSize = widgetSize.sizeForCurrentDevice(iPadTarget: .designCanvas) ?? widgetSize.minimumSize
        
        guard let uiImage = UIImage(named: name, in: bundle, with: nil)?
                .scaledToFit(imageSize)?
                .withRenderingMode(renderingMode)
        else { return nil}
        self.uiImage = uiImage
    }
    
    public init?(symbolName: String, bundle: Bundle? = nil, renderingMode: UIImage.RenderingMode = .alwaysTemplate) {
        guard let uiImage = UIImage(named: symbolName, in: bundle, with: nil)?
            .withRenderingMode(renderingMode)
        else { return nil}
        self.uiImage = uiImage
    }
    
    public var body: Image {
        Image(uiImage: uiImage)
    }
}
#endif
