//
//  UIImage+publicExtensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-09-02.
//

import SwiftUI

#if os(iOS)
public extension UIImage {
    func scale(_ scale: CGFloat) -> UIImage? {
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        /// Change this to UIGraphicsImageRenderer(size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        draw(in: .init(origin: .zero, size: newSize), blendMode: .normal, alpha: 1)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func scaledToFit(_ frame: CGSize) -> UIImage? {
        let newSize = size.scaledToFit(frame)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        draw(in: .init(origin: .zero, size: newSize), blendMode: .normal, alpha: 1)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
#endif
