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
    
    public init?(_ uiImage: UIImage) {
        if uiImage.isSymbolImage {
            self.uiImage = uiImage.withRenderingMode(.alwaysTemplate)
        } else {
            let widgetSize = WidgetSize.accessoryInline
            let imageSize = widgetSize.sizeForCurrentDevice(iPadTarget: .designCanvas) ?? widgetSize.minimumSize
            
            guard let uiImage = uiImage
                .scaledToFit(imageSize)?
                .withRenderingMode(.alwaysTemplate)
            else { return nil}
            self.uiImage = uiImage
        }
    }
    
    public var body: Image {
        Image(uiImage: uiImage)
    }
}

public extension AccessoryInlineImage {
    init?(_ name: String, bundle: Bundle? = nil) {
        guard let uiImage = UIImage(named: name, in: bundle, with: nil) else { return nil}
        self.init(uiImage)
    }
}
#endif
