/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Class that generates a spectrogram from an audio signal.
 */
import AVFoundation
import Accelerate

public class AudioSpectrogram: NSObject, ObservableObject {
        
    // MARK: Initialization
    
    override init() {
        super.init()
        
        configureCaptureSession()
        audioOutput.setSampleBufferDelegate(self,
                                            queue: captureQueue)
        //self.startRunning()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    /// Samples per frame — the height of the spectrogram.
    static let sampleCount = 1024
    
    /// Determines the overlap between frames.
    static let hopCount = 512
    
    let captureSession = AVCaptureSession()
    let audioOutput = AVCaptureAudioDataOutput()
    let captureQueue = DispatchQueue(label: "captureQueue",
                                     qos: .userInitiated,
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)
    let sessionQueue = DispatchQueue(label: "sessionQueue",
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)
    
    let forwardDCT = vDSP.DCT(count: sampleCount,
                              transformType: .II)!
    
    /// The window sequence used to reduce spectral leakage.
    let hanningWindow = vDSP.window(ofType: Float.self,
                                    usingSequence: .hanningDenormalized,
                                    count: sampleCount,
                                    isHalfWindow: false)
    
    let dispatchSemaphore = DispatchSemaphore(value: 1)
    
    /// A buffer that contains the raw audio data from AVFoundation.
    var rawAudioData = [Int16]()
    
    /// A reusable array that contains the current frame of time domain audio data as single-precision
    /// values.
    var timeDomainBuffer = [Float](repeating: 0,
                                   count: sampleCount)
    
    /// A resuable array that contains the frequency domain representation of the current frame of
    /// audio data.
    var frequencyDomainBuffer = [Float](repeating: 0,
                                        count: sampleCount)
    
    @Published var valuesP = [Float](repeating: 0.0, count: 9)
    
    // MARK: Instance Methods
    
    /// Process a frame of raw audio data:
    /// * Convert supplied `Int16` values to single-precision.
    /// * Apply a Hann window to the audio data.
    /// * Perform a forward discrete cosine transform.
    /// * Convert frequency domain values to decibels.
    func processData(values: [Int16]) {
        dispatchSemaphore.wait()
        
        vDSP.convertElements(of: values,
                             to: &timeDomainBuffer)
        
        vDSP.multiply(timeDomainBuffer,
                      hanningWindow,
                      result: &timeDomainBuffer)
        
        forwardDCT.transform(timeDomainBuffer,
                             result: &frequencyDomainBuffer)
        
        vDSP.absolute(frequencyDomainBuffer,
                      result: &frequencyDomainBuffer)
        
        vDSP.convert(amplitude: frequencyDomainBuffer,
                     toDecibels: &frequencyDomainBuffer,
                     zeroReference: Float(AudioSpectrogram.sampleCount))
        
        //Throws warning during runtime, but I could not find a solution to this issue
        self.valuesP = self.reduceDataUnevenly(data: self.frequencyDomainBuffer)
        
        dispatchSemaphore.signal()
        }
    
    func reduceData(data: [Float], numberOfBars: Int) -> [Float]{
        var res: [Float] = []
        let len = data.count / numberOfBars
        for i in stride(from: 0, to: numberOfBars, by: 1) {
            var sum = Float(0)
            for j in stride(from: len*i, to: len * (1 + i), by: 1){
                sum = sum+data[j]+80
            }
            res.append(sum/Float(len))
        }
        //Avoid problems with dividing by zero or multiplying by zero
        for i in 0 ..< res.count {
            if res[i] < 1 {
                res[i] = 1
            }
            
        }
        return res
    }
    
    func reduceDataUnevenly(data: [Float]) -> [Float]{
        var res: [Float] = []
        let arr = [0, 2, 5, 11, 26, 51, 101, 251, 501, 800] //ranges oriented off normal spectograms
        for i in 0...arr.count-2 {
            var sum = Float(0)
            for j in stride(from: arr[i], to: arr[i+1], by: 1) {
                sum = sum+data[j]
            }
            res.append(sum / Float(arr[i+1]-arr[i]) * 3) //*3 for some additional length for the bars
        }
        
        for i in 0 ..< res.count {
            if res[i] < 0 {
                res[i] = 0
            }
            
        }
        return res
    }
}
