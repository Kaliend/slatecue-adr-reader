import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconVariant {
    let filename: String
    let size: Int
}

enum BuildAppIconError: LocalizedError {
    case missingSourceImage
    case failedToDecodeSource
    case failedToCreateContext(size: Int)
    case failedToCreateImageDestination(path: String)
    case failedToFinalizeImage(path: String)

    var errorDescription: String? {
        switch self {
        case .missingSourceImage:
            return "Source icon image was not found."
        case .failedToDecodeSource:
            return "Source icon image could not be decoded."
        case .failedToCreateContext(let size):
            return "Bitmap context for icon size \(size) could not be created."
        case .failedToCreateImageDestination(let path):
            return "PNG destination could not be created for \(path)."
        case .failedToFinalizeImage(let path):
            return "PNG export failed for \(path)."
        }
    }
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = repoRoot.appendingPathComponent("design/AppIcon-source.png")
let iconsetURL = repoRoot.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")

let variants = [
    IconVariant(filename: "icon_16x16.png", size: 16),
    IconVariant(filename: "icon_16x16@2x.png", size: 32),
    IconVariant(filename: "icon_32x32.png", size: 32),
    IconVariant(filename: "icon_32x32@2x.png", size: 64),
    IconVariant(filename: "icon_128x128.png", size: 128),
    IconVariant(filename: "icon_128x128@2x.png", size: 256),
    IconVariant(filename: "icon_256x256.png", size: 256),
    IconVariant(filename: "icon_256x256@2x.png", size: 512),
    IconVariant(filename: "icon_512x512.png", size: 512),
    IconVariant(filename: "icon_512x512@2x.png", size: 1024),
]

guard FileManager.default.fileExists(atPath: sourceURL.path) else {
    throw BuildAppIconError.missingSourceImage
}

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    throw BuildAppIconError.failedToDecodeSource
}

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

for variant in variants {
    let size = variant.size
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw BuildAppIconError.failedToCreateContext(size: size)
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.225

    context.clear(rect)
    context.interpolationQuality = .high
    context.addPath(CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
    context.clip()
    context.draw(sourceImage, in: rect)

    guard let outputImage = context.makeImage() else {
        throw BuildAppIconError.failedToCreateContext(size: size)
    }

    let outputURL = iconsetURL.appendingPathComponent(variant.filename)
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw BuildAppIconError.failedToCreateImageDestination(path: outputURL.path)
    }

    CGImageDestinationAddImage(destination, outputImage, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw BuildAppIconError.failedToFinalizeImage(path: outputURL.path)
    }
}

print("Regenerated AppIcon assets with transparent rounded corners.")
