//
//  QRScannerViewController.swift
//  iOSEventApp
//
//  Created by Nathaniel Brown on 3/5/18.
//  Copyright © 2018 LightSys. All rights reserved.
//

// The majority of this file (whatever enables it to scan QR codes) was downloaded from https://www.hackingwithswift.com/example-code/media/how-to-scan-a-qr-code

import UIKit
import AVFoundation

/**
 So the idea is that you go in to the QR scanner when you open the app. Once the
 QR code has been scanned, the app will stay on that event, sourcing data
 through that hyperlink, until otherwise notified. The ability to change the
 QR code being used is in settings. We downloaded the QR code reader.
 */

// TODO: Increase the tezt size of the button text, on the ipad it's small and will not fit apple's standards
class QRScannerViewController: UIViewController,
AVCaptureMetadataOutputObjectsDelegate {
    
    weak var delegate: MenuButton?
    
    let loader = DataController(newPersistentContainer: (UIApplication.shared.delegate as! AppDelegate).persistentContainer)
    var activityIndicator: UIActivityIndicatorView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func setupSession() {
        var availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .back).devices
        if availableDevices.count == 0 {
            availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .front).devices
        }
        guard availableDevices.count > 0 else {
            let alertController = UIAlertController(title: "No cameras available", message: "Please check camera permissions", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                self.performSegue(withIdentifier: "PresentMainContainer", sender: nil)
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        let device = availableDevices.first(where: { $0.deviceType == .builtInWideAngleCamera }) ?? availableDevices.first!
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch {
            let alertController = UIAlertController(title: "Unable to start video session", message: "Please check camera permissions", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                self.performSegue(withIdentifier: "PresentMainContainer", sender: nil)
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession.inputs.count == 0 {
            setupSession()
        }
        
        // If they arrive on the scanner, they have come back from the main container – and need to (re)scan.
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    // When the app is backgrounded, the capture session is automatically paused, then resumed when foregrounded.
    // Not called when backgrounded. So this is only called when leaving for the main container.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue, completion: { (success) in
                if success == true {
                    self.performSegue(withIdentifier: "PresentMainContainer", sender: nil)
                }
                else {
                    self.captureSession.startRunning()
                }
            })
        }
        else {
            captureSession.startRunning()
        }
    }
    
    /// If there is a url, load data from it. Notify the user of any errors.
    ///
    /// - Parameters:
    ///   - code: The string form of the QR code scanned
    ///   - completion: Performed on the main thread
    func found(code: String, completion: @escaping ((_ success: Bool) -> Void)) {
        if let url = URL(string: code) {
            activityIndicator.startAnimating()
            (UIApplication.shared.delegate as! AppDelegate).persistentContainer.performBackgroundTask { (context) in
                
                // The user won't want notifications from a different event... clear everything except chosen refresh rate
                UserDefaults.standard.removeObject(forKey: "defaultRefreshRateMinutes")
                UserDefaults.standard.removeObject(forKey: "loadedDataURL")
                UserDefaults.standard.removeObject(forKey: "loadedNotificationsURL")
                UserDefaults.standard.removeObject(forKey: "notificationsLastUpdatedAt")
                UserDefaults.standard.removeObject(forKey: "notificationLoadedInBackground")
                UserDefaults.standard.removeObject(forKey: "refreshedDataInBackground")
                
                self.loader.deleteAllObjects(onContext: context)
                
                self.loader.loadDataFromURL(url, completion: { (success, errors, _) in
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        
                        if success == false {
                            let alertController = UIAlertController(title: "Failed to load data", message: DataController.messageForErrors(errors), preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                completion(success)
                            })
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                        else if errors?.count ?? 0 > 0 {
                            let alertController = UIAlertController(title: "Data loaded with some errors", message: DataController.messageForErrors(errors), preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                completion(success)
                            })
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                        else {
                            completion(success)
                        }
                    }
                })
            }
        }
        else {
            let alertController = UIAlertController(title: "Invalid url", message: "\(code) is not a valid url", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                completion(false)
            })
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mainContainer = segue.destination as? MainContainerViewController {
            delegate?.refreshSidebar()
            mainContainer.delegate = delegate
        }
    }
}
