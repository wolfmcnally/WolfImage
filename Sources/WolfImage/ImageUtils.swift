//
//  ImageUtils.swift
//  WolfImage
//
//  Created by Wolf McNally on 7/2/15.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import WolfColor
import WolfGeometry

#if os(macOS)
    public func newImage(withSize size: Size, isOpaque: Bool = false, background: NSColor? = nil, scale: CGFloat = 0.0, isFlipped: Bool = true, renderingMode: OSImageRenderingMode = .automatic, drawing: CGContextBlock? = nil) -> NSImage {
        return newImage(withSize: size.cgSize, isOpaque: isOpaque, background: background, scale: scale, isFlipped: isFlipped, renderingMode: renderingMode, drawing: drawing)
    }

    public func newImage(withSize size: CGSize, isOpaque: Bool = false, background: NSColor? = nil, scale: CGFloat = 0.0, isFlipped: Bool = true, renderingMode: OSImageRenderingMode = .automatic, drawing: CGContextBlock? = nil) -> NSImage {
        let image = NSImage.init(size: size)

        let rep = NSBitmapImageRep.init(bitmapDataPlanes: nil,
                                        pixelsWide: Int(size.width),
                                        pixelsHigh: Int(size.height),
                                        bitsPerSample: 8,
                                        samplesPerPixel: isOpaque ? 3 : 4,
                                        hasAlpha: !isOpaque,
                                        isPlanar: false,
                                        colorSpaceName: NSColorSpaceName.calibratedRGB,
                                        bytesPerRow: 0,
                                        bitsPerPixel: 0)

        image.addRepresentation(rep!)
        image.lockFocus()

        let bounds = CGRect(origin: .zero, size: size)
        let nsContext = NSGraphicsContext.current!
        let context = nsContext.cgContext

        drawInto(context) { context in
            if isOpaque {
                context.setFillColor(background?.cgColor ?? OSColor.black.cgColor)
                context.fill(bounds)
            } else {
                context.clear(bounds)
                if let background = background {
                    context.setFillColor(background.cgColor)
                    context.fill(bounds)
                }
            }
        }

        if let drawing = drawing {
            drawInto(context, isFlipped: isFlipped, bounds: bounds) { context in
                drawing(context)
            }
        }

        image.unlockFocus()
        return image
    }
#else
    public func newImage(withSize size: Size, isOpaque: Bool = false, background: UIColor? = nil, scale: CGFloat = 0.0, isFlipped: Bool = false, renderingMode: OSImageRenderingMode = .automatic, drawing: CGContextBlock? = nil) -> UIImage {
        return newImage(withSize: size.cgSize, isOpaque: isOpaque, background: background, scale: scale, isFlipped: isFlipped, renderingMode: renderingMode, drawing: drawing)
    }

    public func newImage(withSize size: CGSize, isOpaque: Bool = false, background: UIColor? = nil, scale: CGFloat = 0.0, isFlipped: Bool = false, renderingMode: OSImageRenderingMode = .automatic, drawing: CGContextBlock? = nil) -> UIImage {
        guard size.width > 0 && size.height > 0 else {
            fatalError("Size may not be empty.")
        }
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, scale)
        let context = currentGraphicsContext

        let bounds = CGRect(origin: .zero, size: size)

        if let background = background {
            drawInto(context) { context in
                context.setFillColor(background.cgColor)
                context.fill(bounds)
            }
        }

        if let drawing = drawing {
            drawInto(context, isFlipped: isFlipped, bounds: bounds) { context in
                drawing(context)
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(renderingMode)
        UIGraphicsEndImageContext()

        return image
    }
#endif
