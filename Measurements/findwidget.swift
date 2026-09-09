#!/usr/bin/env swift

//
//  findwidget.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-31.
//

/// Finds the probe widget's container background in a screenshot and reports the bounding box of every match, in pixels and in points.
///
/// On iPad `TimelineProviderContext.displaySize` reports the design canvas rather than the frame the widget is drawn in, so measuring a placed widget in a screenshot is the only way to get a rendered iPad frame. See `Measurements/README.md`.
///
/// Runs directly with no build step:
///
/// ```sh
/// Measurements/findwidget.swift shot.png 2            # Home Screen and Today View
/// Measurements/findwidget.swift shot.png 2 bright     # Lock Screen, which renders vibrant
/// Measurements/findwidget.swift shot.png 2 magenta 0,600,1200,800
/// ```

import CoreGraphics
import Foundation
import ImageIO

/// Anything that stops a measurement, reported as a message rather than a crash.
struct ProbeError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

// MARK: - Recognising the widget

/// How a widget pixel is told apart from the rest of the screen.
enum FillMode: String, CaseIterable {
    /// The probe's magenta container background, drawn in full colour.
    case magenta
    /// A bright, near neutral patch.
    ///
    /// The Lock Screen removes the container background and renders vibrant, which turns the magenta into a material keyed on luminance. The widget then shows as a bright area against the wallpaper rather than as a colour, so brightness is all there is left to threshold on.
    case bright

    /// Whether one pixel belongs to the widget.
    ///
    /// Alpha is ignored because a screenshot is opaque.
    func matches(red: UInt8, green: UInt8, blue: UInt8) -> Bool {
        switch self {
        case .magenta:
            return red > 180 && green < 90 && blue > 180
        case .bright:
            let lowest = min(red, green, blue)
            let highest = max(red, green, blue)
            return lowest > 150 && Int(highest) - Int(lowest) < 60
        }
    }
}

// MARK: - Geometry

/// A rectangle in whole pixels.
///
/// Kept separate from `CGRect` so there is never a question of whether a value is a pixel or a point.
struct PixelRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    var maxX: Int { x + width }
    var maxY: Int { y + height }
    var isEmpty: Bool { width <= 0 || height <= 0 }

    func contains(x: Int, y: Int) -> Bool {
        x >= self.x && x < maxX && y >= self.y && y < maxY
    }

    /// The overlap with another rectangle, which may be empty.
    func intersection(_ other: PixelRect) -> PixelRect {
        let x = max(self.x, other.x)
        let y = max(self.y, other.y)
        return PixelRect(
            x: x,
            y: y,
            width: min(maxX, other.maxX) - x,
            height: min(maxY, other.maxY) - y
        )
    }
}

// MARK: - Decoding

/// An 8 bit per channel RGBA copy of a decoded image.
struct Bitmap {
    let width: Int
    let height: Int
    /// Row major RGBA, four bytes per pixel, starting at the top left pixel.
    let pixels: [UInt8]

    var bounds: PixelRect {
        PixelRect(x: 0, y: 0, width: width, height: height)
    }

    /// Decodes an image file and redraws it as sRGB RGBA.
    ///
    /// `ImageIO` reads whatever the file happens to be, so interlacing, bit depth, colour type and even a screenshot that has been re-saved as something other than a PNG are all handled rather than rejected.
    ///
    /// Redrawing into sRGB also pins the colour space. A simulator screenshot is sRGB while one taken on hardware is Display P3, and the same on screen magenta is stored as different numbers in each, so without this the thresholds in ``FillMode`` would quietly mean something different depending on where the screenshot came from.
    init(contentsOf url: URL) throws {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ProbeError("could not decode an image from \(url.path)")
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw ProbeError("could not create the sRGB colour space")
        }

        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else {
            throw ProbeError("could not redraw \(url.lastPathComponent) as sRGB RGBA")
        }

        self.width = width
        self.height = height
        self.pixels = pixels
    }

    func matches(_ mode: FillMode, x: Int, y: Int) -> Bool {
        let index = (y * width + x) * 4
        return mode.matches(red: pixels[index], green: pixels[index + 1], blue: pixels[index + 2])
    }
}

// MARK: - Finding regions

/// A connected run of widget coloured pixels.
struct Region {
    /// Bounding box in image coordinates, in pixels.
    let box: PixelRect
    /// Matching pixels in the region.
    ///
    /// Smaller than the area of the bounding box wherever the widget has rounded corners, so the ratio of the two is a quick check that a match is really a widget and not an oddly shaped patch of wallpaper.
    let pixelCount: Int

    /// Fraction of the bounding box that actually matched.
    var solidity: Double {
        Double(pixelCount) / Double(box.width * box.height)
    }
}

/// Finds every connected region of widget coloured pixels that intersects `searchArea`.
///
/// Regions are 4-connected. Once a matching pixel is found within `searchArea`, its complete region is discovered across the image, so narrowing the search never clips a region or changes the numbers that come out of it.
func findRegions(in bitmap: Bitmap, mode: FillMode, searchArea: PixelRect, minimumSide: Int) -> [Region] {
    let neighbours = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    var visited = [Bool](repeating: false, count: bitmap.width * bitmap.height)
    var found: [Region] = []

    for startY in searchArea.y..<searchArea.maxY {
        for startX in searchArea.x..<searchArea.maxX {
            guard !visited[startY * bitmap.width + startX],
                  bitmap.matches(mode, x: startX, y: startY)
            else { continue }

            visited[startY * bitmap.width + startX] = true
            var stack = [(startX, startY)]
            var minX = startX, maxX = startX, minY = startY, maxY = startY
            var pixelCount = 0

            while let (x, y) = stack.popLast() {
                pixelCount += 1
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)

                for (dx, dy) in neighbours {
                    let nextX = x + dx
                    let nextY = y + dy
                    guard bitmap.bounds.contains(x: nextX, y: nextY),
                          !visited[nextY * bitmap.width + nextX],
                          bitmap.matches(mode, x: nextX, y: nextY)
                    else { continue }
                    visited[nextY * bitmap.width + nextX] = true
                    stack.append((nextX, nextY))
                }
            }

            let box = PixelRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
            if box.width >= minimumSide && box.height >= minimumSide {
                found.append(Region(box: box, pixelCount: pixelCount))
            }
        }
    }
    return found
}

// MARK: - Arguments

/// Command line arguments, in the same order the Python script used so existing notes and `README.md` commands still work.
struct Arguments {
    let url: URL
    /// Pixels per point on the device the screenshot came from, used to convert the measured box to points.
    let scale: Double
    let mode: FillMode
    /// Part of the screenshot to search, or nil for all of it. Worth using when something else on screen matches.
    let crop: PixelRect?

    static let usage = """
        usage: findwidget.swift <screenshot> [scale] [\(FillMode.allCases.map(\.rawValue).joined(separator: "|"))] [cropX,cropY,cropWidth,cropHeight]

          scale  pixels per point on the device the screenshot came from, default 2
          mode   magenta for a full colour render, bright for a vibrant one such as the Lock Screen
          crop   region to search, in pixels
        """

    init(_ commandLine: [String]) throws {
        /// The first argument is the path this script was invoked with.
        let arguments = Array(commandLine.dropFirst())
        guard let path = arguments.first else {
            throw ProbeError(Self.usage)
        }
        url = URL(fileURLWithPath: path)

        if arguments.count > 1 {
            guard let scale = Double(arguments[1]), scale > 0 else {
                throw ProbeError("scale must be a positive number, got \"\(arguments[1])\"\n\n\(Self.usage)")
            }
            self.scale = scale
        } else {
            /// Matches iPad, which is what a screenshot is usually needed for.
            scale = 2
        }

        if arguments.count > 2 {
            /// Checked rather than defaulted, because silently falling back to another mode reads as a widget that could not be found.
            guard let mode = FillMode(rawValue: arguments[2]) else {
                let known = FillMode.allCases.map(\.rawValue).joined(separator: ", ")
                throw ProbeError("unknown mode \"\(arguments[2])\", expected one of: \(known)")
            }
            self.mode = mode
        } else {
            mode = .magenta
        }

        if arguments.count > 3 {
            let parts = arguments[3].split(separator: ",")
            let numbers = parts.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count == 4, numbers.count == 4 else {
                throw ProbeError("crop must be four whole numbers, x,y,width,height, got \"\(arguments[3])\"")
            }
            crop = PixelRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
        } else {
            crop = nil
        }
    }
}

// MARK: - Output

/// Formats a measurement without trailing zeros, matching the `%g` the Python script used so output is comparable with older notes.
func shortestForm(_ value: Double) -> String {
    String(format: "%g", value)
}

// MARK: - Running

/// Regions narrower or shorter than this are ignored.
///
/// Small enough to keep an `accessoryCircular` complication, large enough to drop stray matching pixels in a wallpaper.
let minimumSide = 20

do {
    let arguments = try Arguments(CommandLine.arguments)
    let bitmap = try Bitmap(contentsOf: arguments.url)

    let searchArea: PixelRect
    if let crop = arguments.crop {
        searchArea = crop.intersection(bitmap.bounds)
        guard !searchArea.isEmpty else {
            throw ProbeError("the crop lies outside the \(bitmap.width)x\(bitmap.height) image")
        }
        print("searching (\(searchArea.x),\(searchArea.y)) \(searchArea.width)x\(searchArea.height)")
    } else {
        searchArea = bitmap.bounds
    }

    print("image \(bitmap.width)x\(bitmap.height), scale \(shortestForm(arguments.scale)), mode \(arguments.mode.rawValue)")

    let found = findRegions(in: bitmap, mode: arguments.mode, searchArea: searchArea, minimumSide: minimumSide)
    if found.isEmpty {
        print("no widget-coloured region found")
    }
    for region in found.sorted(by: { $0.pixelCount > $1.pixelCount }) {
        let points = "\(shortestForm(Double(region.box.width) / arguments.scale))x\(shortestForm(Double(region.box.height) / arguments.scale))"
        let solid = String(format: "%.0f", region.solidity * 100)
        print("  at (\(region.box.x),\(region.box.y))  \(region.box.width)x\(region.box.height) px  =  \(points) pt   (region \(solid)% solid)")
    }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
