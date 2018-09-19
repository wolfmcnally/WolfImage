//
//  Canvas.swift
//  WolfImage
//
//  Created by Wolf McNally on 9/16/18.
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

import Foundation
import Accelerate
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import WolfColor
import WolfGeometry
import WolfNumerics

public class Canvas {
    public let bounds: IntRect
    public var clearColor: Color?

    private let chunkyBytesCount: Int
    private let planarFloatsCount: Int
    private let planarFloatsPerRow: Int

    private let argb8Data: UnsafeMutablePointer<UInt8>
    private let argb8PremultipliedData: UnsafeMutablePointer<UInt8>
    private let alphaFData: UnsafeMutablePointer<Float>
    private let redFData: UnsafeMutablePointer<Float>
    private let greenFData: UnsafeMutablePointer<Float>
    private let blueFData: UnsafeMutablePointer<Float>

    private var argb8: vImage_Buffer
    private var argb8Premultiplied: vImage_Buffer
    private var alphaF: vImage_Buffer
    private var redF: vImage_Buffer
    private var greenF: vImage_Buffer
    private var blueF: vImage_Buffer

    private var maxPixelValues: [Float] = [1, 1, 1, 1]
    private var minPixelValues: [Float] = [0, 0, 0, 0]
    private let context: CGContext
    private var _image: OSImage?

    public init(size: IntSize, clearColor: Color? = .black) {
        bounds = size.bounds
        self.clearColor = clearColor

        assert(size.width >= 1, "width must be >= 1")
        assert(size.height >= 1, "height must be >= 1")

        let colorSpace = sharedColorSpaceRGB
        let componentsPerPixel = Int(colorSpace.numberOfComponents) + 1 // alpha

        let chunkyBytesPerComponent = 1
        let chunkyBitsPerComponent = chunkyBytesPerComponent * 8
        let chunkyBytesPerPixel = componentsPerPixel * chunkyBytesPerComponent
        let chunkyBytesPerRow = Int(UInt(size.width * chunkyBytesPerPixel + 15) & ~UInt(0xf))
        chunkyBytesCount = size.height * chunkyBytesPerRow

        let planarBytesPerComponent = MemoryLayout<Float>.size
        let planarBytesPerRow = Int(UInt(size.width * planarBytesPerComponent * componentsPerPixel + 15) & ~UInt(0xf))
        planarFloatsPerRow = planarBytesPerRow >> 2
        planarFloatsCount = size.height * planarFloatsPerRow

        argb8Data = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkyBytesCount)
        argb8PremultipliedData = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkyBytesCount)
        alphaFData = UnsafeMutablePointer<Float>.allocate(capacity: planarFloatsCount)
        redFData = UnsafeMutablePointer<Float>.allocate(capacity: planarFloatsCount)
        greenFData = UnsafeMutablePointer<Float>.allocate(capacity: planarFloatsCount)
        blueFData = UnsafeMutablePointer<Float>.allocate(capacity: planarFloatsCount)

        let uWidth = vImagePixelCount(size.width)
        let uHeight = vImagePixelCount(size.height)

        //        argb8 = vImage_Buffer(data: argb8Data, height: uHeight, width: uWidth, rowBytes: chunkyBytesPerRow)
        argb8 = vImage_Buffer(data: argb8Data, height: vImagePixelCount(size.height), width: uWidth, rowBytes: chunkyBytesPerRow)
        argb8Premultiplied = vImage_Buffer(data: argb8PremultipliedData, height: uHeight, width: uWidth, rowBytes: chunkyBytesPerRow)
        alphaF = vImage_Buffer(data: alphaFData, height: uHeight, width: uWidth, rowBytes: planarBytesPerRow)
        redF = vImage_Buffer(data: redFData, height: uHeight, width: uWidth, rowBytes: planarBytesPerRow)
        greenF = vImage_Buffer(data: greenFData, height: uHeight, width: uWidth, rowBytes: planarBytesPerRow)
        blueF = vImage_Buffer(data: blueFData, height: uHeight, width: uWidth, rowBytes: planarBytesPerRow)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        context = CGContext(data: argb8PremultipliedData, width: size.width, height: size.height, bitsPerComponent: chunkyBitsPerComponent, bytesPerRow: chunkyBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        //println("width:\(width) height:\(height) componentsPerPixel:\(componentsPerPixel) chunkyBytesPerComponent:\(chunkyBytesPerComponent) chunkyBitsPerComponent:\(chunkyBitsPerComponent) chunkyBytesPerPixel:\(chunkyBytesPerPixel) chunkyBytesPerRow:\(chunkyBytesPerRow) chunkyBytesCount:\(chunkyBytesCount)")

        //println("planarBytesPerComponent:\(planarBytesPerComponent) planarBytesPerRow:\(planarBytesPerRow) planarFloatsPerRow:\(planarFloatsPerRow) planarFloatsCount:\(planarFloatsCount)")

        //println("data:\(redF.data) height:\(redF.height) width:\(redF.width) rowBytes:\(redF.rowBytes)")
    }

    deinit {
        argb8Data.deallocate()
        argb8PremultipliedData.deallocate()
        alphaFData.deallocate()
        redFData.deallocate()
        greenFData.deallocate()
        blueFData.deallocate()
    }

    public var image: OSImage {
        get {
            if self._image == nil {
                var error = vImageConvert_PlanarFToARGB8888(&alphaF, &redF, &greenF, &blueF, &argb8, &maxPixelValues, &minPixelValues, UInt32(kvImageNoFlags))
                assert(error == kvImageNoError, "Error when converting canvas to chunky")
                error = vImagePremultiplyData_ARGB8888(&argb8, &argb8Premultiplied, UInt32(kvImageNoFlags))
                assert(error == kvImageNoError, "Error when premultiplying canvas")
                let cgImage = self.context.makeImage()
                #if os(macOS)
                let boundsSize = self.bounds.size
                let size = CGSize(width: CGFloat(boundsSize.width), height: CGFloat(boundsSize.height))
                self._image = NSImage(cgImage: cgImage!, size: size)
                #else
                self._image = UIImage(cgImage: cgImage!)
                #endif
                assert(self._image != nil, "Error when converting")
            }
            return self._image!
        }
    }

    func invalidateImage() {
        self._image = nil
    }

    public func isValidPoint(_ p: IntPoint) -> Bool {
        return p.x >= 0 && p.y >= 0 && p.x < Int(alphaF.width) && p.y < Int(alphaF.height)
    }

    public func clampPoint(_ p: IntPoint) -> IntPoint {
        let px = p.x
        let py = p.y
        let x = min(max(px, bounds.minX), bounds.maxX - 1)
        let y = min(max(py, bounds.minY), bounds.maxY - 1)
        return IntPoint(x: x, y: y)
    }

    private func checkPoint(_ point: IntPoint) {
        assert(point.x >= bounds.minX, "x must be >= 0")
        assert(point.y >= bounds.minY, "y must be >= 0")
        assert(point.x < bounds.size.width, "x must be < width")
        assert(point.y < bounds.size.height, "y must be < height")
    }

    private func offsetForPoint(_ point: IntPoint) -> Int {
        return planarFloatsPerRow * point.y + point.x
    }

    public func setPoint(_ point: IntPoint, to color: Color) {
        checkPoint(point)

        invalidateImage()

        let offset = offsetForPoint(point)
        alphaFData[offset] = Float(color.alpha)
        redFData[offset] = Float(color.red)
        greenFData[offset] = Float(color.green)
        blueFData[offset] = Float(color.blue)
    }

    public func colorAtPoint(_ point: IntPoint) -> Color {
        checkPoint(point)

        let offset = offsetForPoint(point)
        return Color(red: Frac(redFData[offset]), green: Frac(greenFData[offset]), blue: Frac(blueFData[offset]), alpha: Frac(alphaFData[offset]))
    }

    public subscript(point: IntPoint) -> Color {
        get { return colorAtPoint(point) }
        set { setPoint(point, to: newValue) }
    }

    public subscript(x: Int, y: Int) -> Color {
        get { return colorAtPoint(IntPoint(x: x, y: y)) }
        set { setPoint(IntPoint(x: x, y: y), to: newValue) }
    }

    public subscript(xRange: CountableClosedRange<Int>, y: Int) -> Color {
        get { return colorAtPoint(IntPoint(x: xRange.lowerBound, y: y)) }
        set {
            for x in xRange {
                self[x, y] = newValue
            }
        }
    }

    public subscript(x: Int, yRange: CountableClosedRange<Int>) -> Color {
        get { return colorAtPoint(IntPoint(x: x, y: yRange.lowerBound)) }
        set {
            for y in yRange {
                self[x, y] = newValue
            }
        }
    }

    public subscript(xRange: CountableRange<Int>, y: Int) -> Color {
        get { return colorAtPoint(IntPoint(x: xRange.lowerBound, y: y)) }
        set {
            for x in xRange {
                self[x, y] = newValue
            }
        }
    }

    public subscript(x: Int, yRange: CountableRange<Int>) -> Color {
        get { return colorAtPoint(IntPoint(x: x, y: yRange.lowerBound)) }
        set {
            for y in yRange {
                self[x, y] = newValue
            }
        }
    }

    public func clearToColor(_ color: Color) {
        invalidateImage()

        vImageOverwriteChannelsWithScalar_PlanarF(Float(color.red), &redF, UInt32(kvImageNoFlags))
        vImageOverwriteChannelsWithScalar_PlanarF(Float(color.green), &greenF, UInt32(kvImageNoFlags))
        vImageOverwriteChannelsWithScalar_PlanarF(Float(color.blue), &blueF, UInt32(kvImageNoFlags))
        vImageOverwriteChannelsWithScalar_PlanarF(Float(color.alpha), &alphaF, UInt32(kvImageNoFlags))
    }

    public func clear() {
        guard let color = clearColor else { return }
        clearToColor(color)
    }

    public func randomPoint() -> IntPoint {
        return bounds.randomPoint()
    }
}
