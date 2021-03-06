//
//  CoreImageFilters.swift
//  WolfImage
//
//  Created by Wolf McNally on 2/28/17.
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
import CoreImage
import WolfPipe
import WolfFoundation

#if canImport(UIKit)
    import UIKit
#endif

public class CoreImageFilter {
    let filter: CIFilter

    public init(filterName: String) { filter = CIFilter(name: filterName)! }

    public var input: CIImage {
        get { return filter.value(forKey: kCIInputImageKey) as! CIImage }
        set { filter.setValue(newValue, forKey: kCIInputImageKey) }
    }

    public var output: CIImage {
        return filter.outputImage!
    }

    public var inputImage: OSImage {
        get { fatalError() }
        set { input = CIImage(cgImage: newValue.cgImage!) }
    }

    public func outputImage(orientation: OSImageOrientation = .up, scale: CGFloat = 1.0) -> OSImage {
        let context = CIContext()
        let cgImage = context.createCGImage(output, from: output.extent)!
        return OSImage(cgImage: cgImage, scale: scale, orientation: orientation)
    }
}

public class ColorControlsFilter: CoreImageFilter {
    public init() { super.init(filterName: "CIColorControls") }

    public convenience init(saturation: Double = 1.0, brightness: Double = 0.0, contrast: Double = 1.0) {
        self.init()
        self.saturation = saturation
        self.brightness = brightness
        self.contrast = contrast
    }

    public var saturation: Double {
        get { return filter.value(forKey: kCIInputSaturationKey) as? Double ?? 1.0 }
        set { filter.setValue(newValue, forKey: kCIInputSaturationKey) }
    }

    public var brightness: Double {
        get { return filter.value(forKey: kCIInputBrightnessKey) as? Double ?? 0.0 }
        set { filter.setValue(newValue, forKey: kCIInputBrightnessKey) }
    }

    public var contrast: Double {
        get { return filter.value(forKey: kCIInputContrastKey) as? Double ?? 1.0 }
        set { filter.setValue(newValue, forKey: kCIInputContrastKey) }
    }
}

public class ExposureAdjustFilter: CoreImageFilter {
    public init() { super.init(filterName: "CIExposureAdjust") }

    public convenience init(ev: Double = 0.5) {
        self.init()
        self.ev = ev
    }

    public var ev: Double {
        get { return filter.value(forKey: kCIInputEVKey) as? Double ?? 0.5 }
        set { filter.setValue(newValue, forKey: kCIInputEVKey) }
    }
}

public class BlurFilter: CoreImageFilter {
    public init() { super.init(filterName: "CIBoxBlur") }

    public convenience init(radius: Double = 1.0) {
        self.init()
        self.radius = radius
    }

    public var radius: Double {
        get { return filter.value(forKey: kCIInputRadiusKey) as? Double ?? 10.0 }
        set { filter.setValue(newValue, forKey: kCIInputRadiusKey) }
    }
}

public class GaussianBlurFilter: CoreImageFilter {
    public init() { super.init(filterName: "CIGaussianBlur") }

    public convenience init(radius: Double = 1.0) {
        self.init()
        self.radius = radius
    }

    public var radius: Double {
        get { return filter.value(forKey: kCIInputRadiusKey) as? Double ?? 10.0 }
        set { filter.setValue(newValue, forKey: kCIInputRadiusKey) }
    }
}

public class QRCodeGeneratorFilter: CoreImageFilter {
    public init() { super.init(filterName: "CIQRCodeGenerator") }

    public enum CorrectionLevel: String {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"
    }

    public convenience init(string: String, correctionLevel: CorrectionLevel = .medium) {
        let data = string |> toUTF8
        self.init(data: data, correctionLevel: correctionLevel)
    }

    public convenience init(data: Data, correctionLevel: CorrectionLevel = .medium) {
        self.init()
        self.data = data
        self.correctionLevel = correctionLevel
    }

    public var data: Data? {
        get { return filter.value(forKey: "inputMessage" ) as? Data }
        set { filter.setValue(newValue, forKey: "inputMessage" ) }
    }

    public var correctionLevel: CorrectionLevel {
        get {
            let s = filter.value(forKey: "inputCorrectionLevel") as? String ?? CorrectionLevel.medium.rawValue
            return CorrectionLevel(rawValue: s)!
        }
        set { filter.setValue(newValue.rawValue, forKey: "inputCorrectionLevel") }
    }
}

public func |> (lhs: OSImage, rhs: CoreImageFilter) -> CoreImageFilter {
    rhs.inputImage = lhs
    return rhs
}

public func |> (lhs: CoreImageFilter, rhs: CoreImageFilter) -> CoreImageFilter {
    rhs.input = lhs.output
    return rhs
}

public func |> (filter: CoreImageFilter, rhs: (orientation: OSImageOrientation, scale: CGFloat)) -> OSImage {
    return filter.outputImage(orientation: rhs.orientation, scale: rhs.scale)
}
