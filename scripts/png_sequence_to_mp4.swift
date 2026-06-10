import AppKit
import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum EncodeError: Error {
    case badArguments
    case cannotCreateWriter
    case cannotCreateImage(String)
    case cannotCreatePixelBuffer
    case cannotCreateContext
    case appendFailed
}

func makePixelBuffer(from image: CGImage, width: Int, height: Int) throws -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    let attrs: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
    ]
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32ARGB,
        attrs as CFDictionary,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let pixelBuffer else {
        throw EncodeError.cannotCreatePixelBuffer
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(pixelBuffer),
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) else {
        throw EncodeError.cannotCreateContext
    }

    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return pixelBuffer
}

func loadCGImage(_ path: String) throws -> CGImage {
    let url = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: url) else {
        throw EncodeError.cannotCreateImage(path)
    }
    var rect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        throw EncodeError.cannotCreateImage(path)
    }
    return cgImage
}

func encode(frameDirectory: URL, outputURL: URL, fps: Int, width: Int, height: Int) throws {
    if FileManager.default.fileExists(atPath: outputURL.path) {
        try FileManager.default.removeItem(at: outputURL)
    }

    let frameURLs = try FileManager.default.contentsOfDirectory(
        at: frameDirectory,
        includingPropertiesForKeys: nil
    )
    .filter { $0.pathExtension.lowercased() == "png" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let settings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: 4_500_000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        ],
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
    )

    guard writer.canAdd(input) else {
        throw EncodeError.cannotCreateWriter
    }
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let queue = DispatchQueue(label: "llm-wiki-demo-encoder")
    let group = DispatchGroup()
    var thrownError: Error?
    var index = 0
    group.enter()
    input.requestMediaDataWhenReady(on: queue) {
        while input.isReadyForMoreMediaData && index < frameURLs.count {
            do {
                let cgImage = try loadCGImage(frameURLs[index].path)
                let pixelBuffer = try makePixelBuffer(from: cgImage, width: width, height: height)
                let time = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps))
                if !adaptor.append(pixelBuffer, withPresentationTime: time) {
                    throw EncodeError.appendFailed
                }
                index += 1
            } catch {
                thrownError = error
                input.markAsFinished()
                group.leave()
                return
            }
        }
        if index >= frameURLs.count {
            input.markAsFinished()
            group.leave()
        }
    }

    group.wait()
    if let thrownError {
        writer.cancelWriting()
        throw thrownError
    }

    let finishGroup = DispatchGroup()
    finishGroup.enter()
    writer.finishWriting {
        finishGroup.leave()
    }
    finishGroup.wait()
    if writer.status != .completed {
        throw writer.error ?? EncodeError.appendFailed
    }
}

guard CommandLine.arguments.count == 6,
      let fps = Int(CommandLine.arguments[3]),
      let width = Int(CommandLine.arguments[4]),
      let height = Int(CommandLine.arguments[5]) else {
    throw EncodeError.badArguments
}

try encode(
    frameDirectory: URL(fileURLWithPath: CommandLine.arguments[1]),
    outputURL: URL(fileURLWithPath: CommandLine.arguments[2]),
    fps: fps,
    width: width,
    height: height
)
