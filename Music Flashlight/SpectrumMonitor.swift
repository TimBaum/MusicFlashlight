////
////  SpectrumMonitor.swift
////  Music Flashlight
////
////  Created by Tim Baum on 02.06.22.
////
//
//import Foundation
//import AVFoundation
//import Accelerate
//import UIKit
//
//class SpectrumMonitor {
//    /// Samples per frame — the height of the spectrogram.
//    static let sampleCount = 1024
//
//    /// Number of displayed buffers — the width of the spectrogram.
//    static let bufferCount = 768
//
//    /// Determines the overlap between frames.
//    static let hopCount = 512
//    
//    /// A buffer that contains the raw audio data from AVFoundation.
//    var rawAudioData = [Int16]()
//    
//    let captureSession = AVCaptureSession()
//    let audioOutput = AVCaptureAudioDataOutput()
//    
//    let forwardDCT = vDSP.DCT(count: sampleCount,
//                              transformType: .II)!
//    
//    /// The window sequence used to reduce spectral leakage.
//    let hanningWindow = vDSP.window(ofType: Float.self,
//                                    usingSequence: .hanningDenormalized,
//                                    count: sampleCount,
//                                    isHalfWindow: false)
//    
//    let dispatchSemaphore = DispatchSemaphore(value: 1)
//    
//    var frequencyDomainValues = [Float](repeating: 0,
//                                        count: bufferCount * sampleCount)
//    
//    /// A reusable array that contains the current frame of time domain audio data as single-precision
//    /// values.
//    var timeDomainBuffer = [Float](repeating: 0,
//                                   count: sampleCount)
//    
//    /// A resuable array that contains the frequency domain representation of the current frame of
//    /// audio data.
//    var frequencyDomainBuffer = [Float](repeating: 0,
//                                        count: sampleCount)
//    
//    init() {
//        beginConfiguration()
//        
//    }
//
//    func beginConfiguration() {
//        
//        switch AVCaptureDevice.authorizationStatus(for: .audio) {
//            case .authorized:
//                    break
//            case .notDetermined:
//                sessionQueue.suspend()
//                AVCaptureDevice.requestAccess(for: .audio,
//                                              completionHandler: { granted in
//                    if !granted {
//                        fatalError("App requires microphone access.")
//                    } else {
//                        self.beginConfiguration()
//                        self.sessionQueue.resume()
//                    }
//                })
//                return
//            default:
//                // Users can add authorization in "Settings > Privacy > Microphone"
//                // on an iOS device, or "System Preferences > Security & Privacy >
//                // Microphone" on a macOS device.
//                fatalError("App requires microphone access.")
//        }
//        
//        captureSession.beginConfiguration()
//        
//        if captureSession.canAddOutput(audioOutput) {
//            captureSession.addOutput(audioOutput)
//        } else {
//            fatalError("Can't add `audioOutput`.")
//        }
//        
//        guard
//            let microphone = AVCaptureDevice.default(.builtInMicrophone,
//                                                     for: .audio,
//                                                     position: .unspecified),
//            let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
//                fatalError("Can't create microphone.")
//        }
//
//        if captureSession.canAddInput(microphoneInput) {
//            captureSession.addInput(microphoneInput)
//        }
//        
//        captureSession.commitConfiguration()
//        startRunning()
//    }
//    
//    func captureTheAudio(_ output: AVCaptureOutput,
//                         didOutput sampleBuffer: CMSampleBuffer,
//                         from connection: AVCaptureConnection) {
//        var audioBufferList = AudioBufferList()
//        var blockBuffer: CMBlockBuffer?
//
//        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
//            sampleBuffer,
//            bufferListSizeNeededOut: nil,
//            bufferListOut: &audioBufferList,
//            bufferListSize: MemoryLayout.stride(ofValue: audioBufferList),
//            blockBufferAllocator: nil,
//            blockBufferMemoryAllocator: nil,
//            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
//            blockBufferOut: &blockBuffer)
//
//        guard let data = audioBufferList.mBuffers.mData else {
//            return
//        }
//        
//        if self.rawAudioData.count < SpectrumMonitor.sampleCount * 2 {
//            let actualSampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
//            
//            let ptr = data.bindMemory(to: Int16.self, capacity: actualSampleCount)
//            let buf = UnsafeBufferPointer(start: ptr, count: actualSampleCount)
//            
//            rawAudioData.append(contentsOf: Array(buf))
//        }
//        
//        while self.rawAudioData.count >= SpectrumMonitor.sampleCount {
//            let dataToProcess = Array(self.rawAudioData[0 ..< SpectrumMonitor.sampleCount])
//            self.rawAudioData.removeFirst(SpectrumMonitor.hopCount)
//            self.processData(values: dataToProcess)
//        }
//
//        createAudioSpectrogram()
//    }
//    
//    func processData(values: [Int16]) {
//        dispatchSemaphore.wait()
//        
//        vDSP.convertElements(of: values,
//                             to: &timeDomainBuffer)
//        
//        vDSP.multiply(timeDomainBuffer,
//                      hanningWindow,
//                      result: &timeDomainBuffer)
//        
//        forwardDCT.transform(timeDomainBuffer,
//                             result: &frequencyDomainBuffer)
//        
//        vDSP.absolute(frequencyDomainBuffer,
//                      result: &frequencyDomainBuffer)
//        
//        vDSP.convert(amplitude: frequencyDomainBuffer,
//                     toDecibels: &frequencyDomainBuffer,
//                     zeroReference: Float(SpectrumMonitor.sampleCount))
//        
//        if frequencyDomainValues.count > SpectrumMonitor.sampleCount {
//            frequencyDomainValues.removeFirst(SpectrumMonitor.sampleCount)
//        }
//        
//        frequencyDomainValues.append(contentsOf: frequencyDomainBuffer)
//
//        dispatchSemaphore.signal()
//    }
//    
//    static var redTable: [Pixel_8] = (0 ... 255).map {
//        return brgValue(from: $0).red
//    }
//
//    static var greenTable: [Pixel_8] = (0 ... 255).map {
//        return brgValue(from: $0).green
//    }
//
//    static var blueTable: [Pixel_8] = (0 ... 255).map {
//        return brgValue(from: $0).blue
//    }
//
//    
//    #if os(iOS)
//    typealias Color = UIColor
//    #else
//    typealias Color = NSColor
//    #endif
//
//    static func brgValue(from value: Pixel_8) -> (red: Pixel_8,
//                                                  green: Pixel_8,
//                                                  blue: Pixel_8) {
//        let normalizedValue = CGFloat(value) / 255
//        
//        // Define `hue` that's blue at `0.0` to red at `1.0`.
//        let hue = 0.6666 - (0.6666 * normalizedValue)
//        let brightness = sqrt(normalizedValue)
//
//        let color = Color(hue: hue,
//                          saturation: 1,
//                          brightness: brightness,
//                          alpha: 1)
//        
//        var red = CGFloat()
//        var green = CGFloat()
//        var blue = CGFloat()
//        
//        color.getRed(&red,
//                     green: &green,
//                     blue: &blue,
//                     alpha: nil)
//        
//        return (Pixel_8(green * 255),
//                Pixel_8(red * 255),
//                Pixel_8(blue * 255))
//    }
//    
//    var rgbImageFormat: vImage_CGImageFormat = {
//        guard let format = vImage_CGImageFormat(
//                bitsPerComponent: 8,
//                bitsPerPixel: 8 * 4,
//                colorSpace: CGColorSpaceCreateDeviceRGB(),
//                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
//                renderingIntent: .defaultIntent) else {
//            fatalError("Can't create image format.")
//        }
//        
//        return format
//    }()
//    
//    /// RGB vImage buffer that contains a vertical representation of the audio spectrogram.
//    lazy var rgbImageBuffer: vImage_Buffer = {
//        guard let buffer = try? vImage_Buffer(width: SpectrumMonitor.sampleCount,
//                                              height: SpectrumMonitor.bufferCount,
//                                              bitsPerPixel: rgbImageFormat.bitsPerPixel) else {
//            fatalError("Unable to initialize image buffer.")
//        }
//        return buffer
//    }()
//
//    /// RGB vImage buffer that contains a horizontal representation of the audio spectrogram.
//    lazy var rotatedImageBuffer: vImage_Buffer = {
//        guard let buffer = try? vImage_Buffer(width: SpectrumMonitor.bufferCount,
//                                              height: SpectrumMonitor.sampleCount,
//                                              bitsPerPixel: rgbImageFormat.bitsPerPixel)  else {
//            fatalError("Unable to initialize rotated image buffer.")
//        }
//        return buffer
//    }()
//    
//    var maxFloat: Float = {
//        var maxValue = [Float(Int16.max)]
//        vDSP.convert(amplitude: maxValue,
//                     toDecibels: &maxValue,
//                     zeroReference: Float(SpectrumMonitor.sampleCount))
//        return maxValue[0] * 2
//    }()
//    
//    func createAudioSpectrogram() {
//        let maxFloats: [Float] = [255, maxFloat, maxFloat, maxFloat]
//        let minFloats: [Float] = [255, 0, 0, 0]
//        
//        frequencyDomainValues.withUnsafeMutableBufferPointer {
//            var planarImageBuffer = vImage_Buffer(data: $0.baseAddress!,
//                                                  height: vImagePixelCount(SpectrumMonitor.bufferCount),
//                                                  width: vImagePixelCount(SpectrumMonitor.sampleCount),
//                                                  rowBytes: SpectrumMonitor.sampleCount * MemoryLayout<Float>.stride)
//            
//            vImageConvert_PlanarFToARGB8888(&planarImageBuffer,
//                                            &planarImageBuffer, &planarImageBuffer, &planarImageBuffer,
//                                            &rgbImageBuffer,
//                                            maxFloats, minFloats,
//                                            vImage_Flags(kvImageNoFlags))
//        }
//        
//        vImageTableLookUp_ARGB8888(&rgbImageBuffer, &rgbImageBuffer,
//                                   nil,
//                                   &SpectrumMonitor.redTable,
//                                   &SpectrumMonitor.greenTable,
//                                   &SpectrumMonitor.blueTable,
//                                   vImage_Flags(kvImageNoFlags))
//        
//        vImageRotate90_ARGB8888(&rgbImageBuffer,
//                                &rotatedImageBuffer,
//                                UInt8(kRotate90DegreesCounterClockwise),
//                                [UInt8()],
//                                vImage_Flags(kvImageNoFlags))
//        
//        print(rotatedImageBuffer)
//        
//        if let image = try? rotatedImageBuffer.createCGImage(format: rgbImageFormat) {
//            DispatchQueue.main.async {
//                return
//            }
//        }
//    }
//    let sessionQueue = DispatchQueue(label: "sessionQueue",
//                                     attributes: [],
//                                     autoreleaseFrequency: .workItem)
//    /// Starts the audio spectrogram.
//    func startRunning() {
//        sessionQueue.async {
//            if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
//                self.captureSession.startRunning()
//            }
//        }
//    }
//}
//
//
