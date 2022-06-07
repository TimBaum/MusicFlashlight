///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//The view controller.
//*/
//
//import AVFoundation
//import Accelerate
//import UIKit
//
//// Note that you must add a "Privacy - Microphone Usage Description" entry
//// to `Info.plist`.
//
//class ViewController: UIViewController {
//
//    /// The audio spectrogram layer.
//    let spectrumMonitor = SpectrumMonitor()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        spectrumMonitor.contentsGravity = .resize
//        view.layer.addSublayer(spectrumMonitor)
//
//        view.backgroundColor = .black
//
//        spectrumMonitor.startRunning()
//    }
//
//    override func viewDidLayoutSubviews() {
//        spectrumMonitor.frame = view.frame
//    }
//
//    override var prefersHomeIndicatorAutoHidden: Bool {
//        true
//    }
//
//    override var prefersStatusBarHidden: Bool {
//        true
//    }
//}
