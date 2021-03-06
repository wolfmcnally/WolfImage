//
//  PDF.swift
//  WolfImage
//
//  Created by Wolf McNally on 12/21/15.
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
import CoreGraphics
import WolfGeometry
import WolfFoundation

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public class PDF {
    private let pdf: CGPDFDocument
    public let pageCount: Int

    public init(url: URL) {
        pdf = CGPDFDocument(url as NSURL)!
        pageCount = pdf.numberOfPages
    }

    public convenience init?(named name: String, inSubdirectory subdirectory: String? = nil, in bundle: Bundle? = nil) {
        let bundle = bundle ?? Bundle.main
        if let url = bundle.url(forResource: name, withExtension: "pdf", subdirectory: subdirectory) {
            self.init(url: url)
        } else {
            return nil
        }
    }

    public init(data: Data) {
        let provider = CGDataProvider(data: data as NSData)!
        pdf = CGPDFDocument(provider)!
        pageCount = pdf.numberOfPages
    }

    public func getSize(ofPageAtIndex index: Int = 0) -> CGSize {
        return getSize(ofPage: getPage(atIndex: index))
    }

    #if os(iOS) || os(tvOS)
    public func drawImage(into context: CGContext, page index: Int = 0, size: CGSize? = nil) {
        let page = getPage(atIndex: index)
        let size = size ?? getSize(ofPageAtIndex: index)
        let bounds = size.bounds
        let cropBox = page.getBoxRect(.cropBox)
        let scaling = CGVector(size: bounds.size) / CGVector(size: cropBox.size)
        let transform = CGAffineTransform(scaling: scaling)
        drawInto(context) { context in
            context.concatenate(transform)
            context.drawPDFPage(page)
        }
    }

    public func getImage(forPageAtIndex index: Int = 0, size: CGSize? = nil, scale: CGFloat = 0.0, renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        let page = getPage(atIndex: index)
        let size = size ?? getSize(ofPageAtIndex: index)
        let bounds = size.bounds
        let cropBox = page.getBoxRect(.cropBox)
        let scaling = CGVector(size: bounds.size) / CGVector(size: cropBox.size)
        let transform = CGAffineTransform(scaling: scaling)
        return newImage(withSize: size, isOpaque: false, scale: scale, isFlipped: true, renderingMode: renderingMode) { context in
            context.concatenate(transform)
            context.drawPDFPage(page)
        }
    }

    public func getImage(forPageAtIndex index: Int = 0, fittingSize: CGSize, scale: CGFloat = 0.0, renderingMode: UIImage.RenderingMode = .automatic) -> UIImage? {
        guard fittingSize.width > 0 || fittingSize.height > 0 else { return nil }
        let size = getSize(ofPageAtIndex: index)
        let newSize = size.aspectFit(within: fittingSize)
        return getImage(forPageAtIndex: index, size: newSize, scale: scale, renderingMode: renderingMode)
    }

    public func getImage() -> UIImage {
        return getImage(forPageAtIndex: 0)
    }
    #endif

    //
    // MARK: - Private
    //

    private func getPage(atIndex index: Int) -> CGPDFPage {
        assert(index < pageCount)
        return pdf.page(at: index + 1)!
    }

    private func getSize(ofPage page: CGPDFPage) -> CGSize {
        var size = page.getBoxRect(.cropBox).size
        let rotationAngle = page.rotationAngle
        if rotationAngle == 90 || rotationAngle == 270 {
            size = size.swapped()
        }
        return size
    }
}

extension PDF: Serializable {
    public func serialize() -> Data {
        fatalError("PDFs may only be deserialized.")
    }

    public static func deserialize(from data: Data) throws -> PDF {
        return PDF(data: data)
    }
}
