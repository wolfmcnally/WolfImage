//
//  DrawCrossedBox.swift
//  WolfImage
//
//  Created by Wolf McNally on 7/18/17.
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
import WolfOSBridge

public func drawCrossedBox(into context: CGContext, frame: CGRect, color: OSColor = .red, lineWidth: CGFloat = 1, showOriginIndicators: Bool = true) {
    let insetFrame = frame.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    drawInto(context) { context in
        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        context.stroke(insetFrame)
        context.move(to: insetFrame.minXminY)
        context.addLine(to: insetFrame.maxXmaxY)
        context.move(to: insetFrame.minXmaxY)
        context.addLine(to: insetFrame.maxXminY)
        if showOriginIndicators {
            context.move(to: insetFrame.midXmidY)
            context.addLine(to: insetFrame.midXminY)
            context.move(to: insetFrame.midXmidY)
            context.addLine(to: insetFrame.minXmidY)
        }
        context.strokePath()
    }
}

public func drawCrossedBox(into context: CGContext, size: CGSize, color: OSColor = .red, lineWidth: CGFloat = 1, showOriginIndicators: Bool = true) {
    let frame = CGRect(origin: .zero, size: size)
    drawCrossedBox(into: context, frame: frame, color: color, lineWidth: lineWidth, showOriginIndicators: showOriginIndicators)
}

public func drawDot(into context: CGContext, at point: CGPoint, radius: CGFloat = 2.0, color: OSColor = .red) {
    let r = CGRect(origin: point, size: .zero).insetBy(dx: -radius, dy: -radius)
    drawInto(context) { context in
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: r)
    }
}
