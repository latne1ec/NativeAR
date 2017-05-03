//
//  ViewController.swift
//  ARPlay
//
//  Created by Evan Latner on 9/25/16.
//  Copyright © 2016 levellabs. All rights reserved.
//

import UIKit
import AVFoundation
import SceneKit
import CoreMotion
import MapKit

class ViewController: UIViewController, SCNSceneRendererDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var motionManager : CMMotionManager?
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var scene : SCNScene?
    var scnView : SCNView?
    var cameraNode : SCNNode?
    var initialAttitude : CMAttitude?
    
    var map : MKMapView?
    var mapBkg : UIView?
    var blurEffectView : UIVisualEffectView?
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCameraBackground()
        
        // Create Scene
        scene = SCNScene()
        
        let newView = SCNView()
        newView.delegate = self
        newView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        newView.backgroundColor = UIColor.clear

        // Retrieve the SCNView
        self.scnView  = newView
        self.scnView!.delegate = self
        self.scnView!.isPlaying = true
        
        self.scnView!.scene = scene
        self.view.addSubview(newView)

        
        self.createSceneCamera()
        //self.sceneSetup()
        let tap = UITapGestureRecognizer(target: self, action: #selector(createBall))
        self.view.addGestureRecognizer(tap)
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView!.frame = view.bounds
        blurEffectView?.alpha = 0.0
        blurEffectView!.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.view.addSubview(blurEffectView!)
        
        map = MKMapView()
        map!.frame = CGRect(x: 12, y: self.view.frame.size.height-102, width: 90, height: 90)
        map!.layer.cornerRadius = map!.frame.size.width/2
        map!.alpha = 0.666
        map!.delegate = self
        map!.layer.borderWidth = 4
        map!.layer.borderColor = UIColor.white.cgColor
        map!.isUserInteractionEnabled = false
        map!.showsUserLocation = true
        //self.view.addSubview(map!)
        //self.view.bringSubview(toFront: map!)
        
        mapBkg = UIView()
        mapBkg?.frame = self.view.frame
        
        
//        let mapButton = UIButton()
//        mapButton.frame = CGRect(x: 12, y: self.view.frame.size.height-102, width: 90, height: 90)
//        mapButton.backgroundColor = UIColor.clear
//        mapButton.addTarget(self, action: #selector(selectMap), for: UIControlEvents.touchDown)
//        mapButton.addTarget(self, action: #selector(releaseMap), for: UIControlEvents.touchDragExit)
//        mapButton.addTarget(self, action: #selector(showMapFullscreen), for: UIControlEvents.touchUpInside)
//        self.view.addSubview(mapButton)
//        self.view.bringSubview(toFront: mapButton)
        
    }
    
    func selectMap () {
        UIView.animate(withDuration: 0.12, animations: {
            self.map?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { (true) in
        }) 
    }
    
    func releaseMap () {
        
        UIView.animate(withDuration: 0.1, animations: {
            self.map?.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
        }, completion: { (true) in
            UIView.animate(withDuration: 0.09, animations: {
                self.map?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: { (true) in
            }) 
        }) 
    }
    
    func showMapFullscreen () {
        
        UIView.animate(withDuration: 0.12, animations: {
            self.map?.frame = CGRect(x: 6, y: 6, width: self.view.frame.size.width-12, height: self.view.frame.size.height-12)
            self.map?.layer.cornerRadius = 8
            self.blurEffectView?.alpha = 1.0
        }, completion: { (true) in
            self.map?.isUserInteractionEnabled = true
            self.map?.alpha = 0.98
        }) 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map!.setRegion(region, animated: true)
        
        let camera = map!.camera
        camera.pitch = 45
        camera.altitude = 100
        map!.setCamera(camera, animated: true)
        
        self.locationManager.stopUpdatingLocation()
        
    }

    func createBall () {
        
        self.sceneSetup()
        
        // Create Ball
        let ball = SCNSphere(radius: 2.0)
        let boingBallNode = SCNNode(geometry: ball)
        boingBallNode.position = SCNVector3(x: 0, y: 0, z: -12)
        
        let material = SCNMaterial()
        material.specular.contents = UIColor.red
        material.diffuse.contents = UIColor.red
        material.shininess = 1.0
        ball.materials = [ material ]

        scene!.rootNode.addChildNode(boingBallNode)
        
        let animation2 = CABasicAnimation(keyPath: "position.y")
        animation2.toValue = cameraNode?.eulerAngles.y
        //animation2.delegate = self
        animation2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        animation2.autoreverses = false
        animation2.repeatCount = 0
        animation2.duration = 5.0
        boingBallNode.addAnimation(animation2, forKey: "fly2")
        
    }
    
    func createSceneCamera () {
        
        // Create camera
        self.cameraNode = SCNNode()
        self.cameraNode!.camera = SCNCamera()
        self.cameraNode!.position = SCNVector3(x: 0.0, y:0.0, z:15)
        
        // Create light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene!.rootNode.addChildNode(lightNode)
        
        // Create ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene!.rootNode.addChildNode(ambientLightNode)
        
        // Make the camera move
        let camera_anim = CABasicAnimation(keyPath: "position.y")
        camera_anim.byValue = 0.0
        camera_anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        camera_anim.autoreverses = true
        camera_anim.repeatCount = Float.infinity
        camera_anim.duration = 10000.0
        
        self.cameraNode!.addAnimation(camera_anim, forKey: "camera_motion")
        scene!.rootNode.addChildNode(self.cameraNode!)
        
    }
    
    func sceneSetup() {
        
        if (motionManager == nil) {
            motionManager = CMMotionManager()
        }
        
        if (motionManager?.isDeviceMotionAvailable != nil) {
            motionManager?.deviceMotionUpdateInterval = 1.0/60.0;
            motionManager?.startDeviceMotionUpdates(to: OperationQueue()) { data, error in
                    if self.initialAttitude == nil {
                        
                        // Capture the initial position
                        self.initialAttitude = data!.attitude
                        return
                    }
                    
                    
                    // make the new position value to be comparative to initial one
                    data!.attitude.multiply(byInverseOf: self.initialAttitude!)
                    
                    let xRotationDelta: Float = (Float)((data?.attitude.pitch)!)
                    let yRotationDelta: Float = (Float)((data?.attitude.roll)!)
                    let zRotationDelta: Float = (Float)((data?.attitude.yaw)!)
                    
                    OperationQueue.main.addOperation({ () -> Void in
                        self.rotateCamera(-yRotationDelta, y: xRotationDelta, z: zRotationDelta)
                    })
            }
        }
        
        
//        if (motionManager?.isDeviceMotionAvailable != nil) {
//            motionManager?.deviceMotionUpdateInterval = 1.0/60.0;
//            motionManager?.startDeviceMotionUpdates(to: OperationQueue(), withHandler: {
//                [weak self] (data:CMDeviceMotion?, error:NSError?) -> Void in
//                if self!.initialAttitude == nil {
//                    
//                    // Capture the initial position
//                    self!.initialAttitude = data!.attitude
//                    return
//                }
//
//        
//                // make the new position value to be comparative to initial one
//                data!.attitude.multiply(byInverseOf: self!.initialAttitude!)
//                
//                let xRotationDelta: Float = (Float)((data?.attitude.pitch)!)
//                let yRotationDelta: Float = (Float)((data?.attitude.roll)!)
//                let zRotationDelta: Float = (Float)((data?.attitude.yaw)!)
//
//                OperationQueue.main.addOperation({ () -> Void in
//                    self?.rotateCamera(-yRotationDelta, y: xRotationDelta, z: zRotationDelta)
//                })
//                })
//        }
    }
    
    func rotateCamera(_ x: Float, y: Float, z: Float) {
        
        self.cameraNode?.eulerAngles.x = y
        self.cameraNode?.eulerAngles.y = -x
        self.cameraNode?.eulerAngles.z = z
        
    }


    func setupCameraBackground () {
        captureSession = AVCaptureSession()
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                previewLayer!.frame = self.view.frame
                self.view.layer.addSublayer(previewLayer!)
                captureSession!.startRunning()
            }
        }
    }
}

