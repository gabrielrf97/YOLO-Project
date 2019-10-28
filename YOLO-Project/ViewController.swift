//
//  ViewController.swift
//  YOLO-Project
//
//  Created by Gabriel on 25/10/19.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation
import VideoToolbox

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var boxesView: BoxesView!
    @IBOutlet weak var observationCount: UILabel?
    
    var tracker : Int = 0
    
    var predictions = [VNRecognizedObjectObservation]() {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.resultsTableView.reloadData()
                self.boxesView.predictions = self.predictions
                self.observationCount?.text = "\(self.predictions.count)"
            }
        }
    }
    
    let visionSequenceHandler = VNSequenceRequestHandler()
    
    lazy var cameraLayer: AVCaptureVideoPreviewLayer = { 
        let layer = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        layer.videoGravity = .resizeAspectFill
        layer.connection?.videoOrientation = .portrait
        return layer
    }()

    lazy var cameraSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
        else { return session }
        session.addInput(input)
        return session
    }()
    
    var request: VNCoreMLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCamera()
        configureRequest()
        configureTableView()
        configureView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cameraLayer.frame = self.cameraView.bounds
    }
    
    func configureView() {
        observationCount?.layer.zPosition = 100
    }
    
    func configureTableView() {
        self.resultsTableView.backgroundColor = UIColor.gray.withAlphaComponent(0.15)
    }
    
    func configureCamera() {
        self.cameraView?.layer.addSublayer(self.cameraLayer)
        boxesView.frame = cameraLayer.frame
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.cameraSession.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        self.cameraSession.startRunning()
    }

    func configureRequest() {
        
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            fatalError("Unable to create YOLO model")
        }
        
        request = VNCoreMLRequest(model: model) { (request, error) in
            if let _predictions = request.results as? [VNRecognizedObjectObservation] {
                self.predictions.removeAll() 
                self.predictions = _predictions
            }
        }
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //Improvement to reduce processment amount because of device limitations (6s). Can be deleted
        if tracker % 15 == 0 {
            let cvPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer!)
            do {
                if let _request = request {
                    try handler.perform([_request])
                }
            } catch {
                return
            }
        }
        tracker += 1
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return predictions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let identifier = predictions[indexPath.section].labels.first?.identifier,
            let confidence = predictions[indexPath.section].labels.first?.confidence else {
            return cell
        }
        cell.textLabel?.text = "\(identifier)"
        cell.textLabel?.textColor = .white
        let percentual = Int(confidence * 100)
        cell.detailTextLabel?.text = "\(percentual)%"
        cell.detailTextLabel?.textColor = .white
        cell.layer.cornerRadius = 8
        cell.layer.masksToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
}
