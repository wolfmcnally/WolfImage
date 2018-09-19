//
//  CGUtils.swift
//  WolfImage
//
//  Created by Wolf McNally on 5/22/16.
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

import CoreGraphics
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

import WolfColor
import WolfGeometry

public typealias CGContextBlock = (CGContext) -> Void

public func flipContext(_ context: CGContext, height: CGFloat) {
    context.translateBy(x: 0.0, y: height)
    context.scaleBy(x: 1.0, y: -1.0)
}

public func drawInto(_ context: CGContext, isFlipped: Bool = false, bounds: CGRect? = nil, drawing: CGContextBlock) {
    context.saveGState()
    if isFlipped { flipContext(context, height: bounds!.height) }
    drawing(context)
    context.restoreGState()
}

public func drawIntoCurrentContext(isFlipped: Bool = false, bounds: CGRect? = nil, drawing: CGContextBlock) {
    drawInto(currentGraphicsContext, isFlipped: isFlipped, bounds: bounds, drawing: drawing)
}

public var currentGraphicsContext: CGContext {
    #if os(macOS)
        return NSGraphicsContext.current!.cgContext
    #else
        return UIGraphicsGetCurrentContext()!
    #endif
}

public func rotateContext(_ context: CGContext, by angle: CGFloat, around point: CGPoint) {
    context.concatenate(context.ctm.rotated(by: angle, around: point))
}

public func drawPlaceholderRect(_ rect: CGRect, lineWidth: CGFloat = 1, color: OSColor? = nil) {
    let color = color ?? OSColor(white: 0.5, alpha: 0.5)
    drawIntoCurrentContext { context in
        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        let rect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        context.stroke(rect)
        context.setLineCap(.round)
        let path = OSBezierPath()
        path.lineWidth = lineWidth
        path.move(to: rect.minXminY)
        path.addLine(to: rect.maxXmaxY)
        path.move(to: rect.maxXminY)
        path.addLine(to: rect.minXmaxY)
        path.stroke()
    }
}

//extension CGFloat: JSONRepresentable {
//    public var json: JSON { return JSON(Double(self)) }
//}
