//
//  AudioMonitor.swift
//  Music Flashlight
//
//  Created by Tim Baum on 28.04.22.
//

import Foundation
import AVFAudio
import AVFoundation

class AudioMonitor: ObservableObject {
    
    
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    
    var threshhold: Float =  -30.0
    var strictMode = false
    private var active = false
    
    @Published public var volume: Float
    
    init() {
        //-160 is the minimum volume (and 0 the max)
        self.volume = -160.0
        self.currentSample = 0
        
        //ask for audio permission
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        
        //store temp audio file in this path
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        //configure recorder
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /**
     start monitoring the audio and controlling the flash
     */
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        //update every 0.005 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.volume = self.audioRecorder.averagePower(forChannel: 0)
            self.toggleFlash()
        })
    }
    
    /**
     control the flash based on the volume
     */
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            //lock, so torch cant be used
            try device.lockForConfiguration()
            //check if the volume is higher than the treshold
            if (self.volume > threshhold) {
                let level: Float
                //if strict mode is activated, level is 1
                if strictMode == true {
                    level = 1
                } else {
                    level =  1 + self.volume / -self.threshhold
                }
                try device.setTorchModeOn(level: level)
            } else {
                device.torchMode = .off
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    /**
     stop monitoring
     */
    private func stopMonitoring() {
        timer?.invalidate()
        audioRecorder.stop()
        self.volume = -160
        toggleFlash()
    }
    
    /**
     toggle the monitoring process
     */
    func toggleMonitoring() {
        if active == false {
            startMonitoring()
            active = true
        } else {
            stopMonitoring()
            active = false
        }
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}
