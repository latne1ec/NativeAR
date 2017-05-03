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
        newView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        newView.backgroundColor = UIColor.clearColor()

        // Retrieve the SCNView
        self.scnView  = newView
        self.scnView!.delegate = self
        self.scnView!.playing = true
        
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
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView!.frame = view.bounds
        blurEffectView?.alpha = 0.0
        blurEffectView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight] // for supporting device rotation
        self.view.addSubview(blurEffectView!)
        
        map = MKMapView()
        map!.frame = CGRectMake(12, self.view.frame.size.height-102, 90, 90)
        map!.layer.cornerRadius = map!.frame.size.width/2
        map!.alpha = 0.666
        map!.delegate = self
        map!.layer.borderWidth = 4
        map!.layer.borderColor = UIColor.whiteColor().CGColor
        map!.userInteractionEnabled = false
        map!.showsUserLocation = true
        self.view.addSubview(map!)
        self.view.bringSubviewToFront(map!)
        
        mapBkg = UIView()
        mapBkg?.frame = self.view.frame
        
        
        let mapButton = UIButton()
        mapButton.frame = CGRectMake(12, self.view.frame.size.height-102, 90, 90)
        mapButton.backgroundColor = UIColor.clearColor()
        mapButton.addTarget(self, action: #selector(selectMap), forControlEvents: UIControlEvents.TouchDown)
        mapButton.addTarget(self, action: #selector(releaseMap), forControlEvents: UIControlEvents.TouchDragExit)
        mapButton.addTarget(self, action: #selector(showMapFullscreen), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(mapButton)
        self.view.bringSubviewToFront(mapButton)
        
    }
    
    func selectMap () {
        UIView.animateWithDuration(0.12, animations: {
            self.map?.transform = CGAffineTransformMakeScale(0.9, 0.9)
            }) { (true) in
        }
    }
    
    func releaseMap () {
        
        UIView.animateWithDuration(0.1, animations: {
            self.map?.transform = CGAffineTransformMakeScale(1.07, 1.07)
        }) { (true) in
            UIView.animateWithDuration(0.09, animations: {
                self.map?.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (true) in
            }
        }
    }
    
    func showMapFullscreen () {
        
        UIView.animateWithDuration(0.12, animations: {
            self.map?.frame = CGRectMake(6, 6, self.view.frame.size.width-12, self.view.frame.size.height-12)
            self.map?.layer.cornerRadius = 8
            self.blurEffectView?.alpha = 1.0
        }) { (true) in
            self.map?.userInteractionEnabled = true
            self.map?.alpha = 0.98
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
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
        material.specular.contents = UIColor.redColor()
        material.diffuse.contents = UIColor.redColor()
        material.shininess = 1.0
        ball.materials = [ material ]

        scene!.rootNode.addChildNode(boingBallNode)
        
        let animation2 = CABasicAnimation(keyPath: "position.y")
        animation2.toValue = cameraNode?.eulerAngles.y
        animation2.delegate = self
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
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene!.rootNode.addChildNode(lightNode)
        
        // Create ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
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
        
        if (motionManager?.deviceMotionAvailable != nil) {
            motionManager?.deviceMotionUpdateInterval = 1.0/60.0;
            motionManager?.startDeviceMotionUpdatesToQueue(NSOperationQueue(), withHandler: {
                [weak self] (data:CMDeviceMotion?, error:NSError?) -> Void in
                if self!.initialAttitude == nil {
                    
                    // Capture the initial position
                    self!.initialAttitude = data!.attitude
                    return
                }

        
                // make the new position value to be comparative to initial one
                data!.attitude.multiplyByInverseOfAttitude(self!.initialAttitude!)
                
                let xRotationDelta: Float = (Float)((data?.attitude.pitch)!)
                let yRotationDelta: Float = (Float)((data?.attitude.roll)!)
                let zRotationDelta: Float = (Float)((data?.attitude.yaw)!)
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self?.rotateCamera(-yRotationDelta, y: xRotationDelta, z: zRotationDelta)
                })
                })
        }
    }
    
    func rotateCamera(x: Float, y: Float, z: Float) {
        
        self.cameraNode?.eulerAngles.x = y
        self.cameraNode?.eulerAngles.y = -x
        self.cameraNode?.eulerAngles.z = z
        
    }


    func setupCameraBackground () {
        captureSession = AVCaptureSession()
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
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
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewLayer!.frame = self.view.frame
                self.view.layer.addSublayer(previewLayer!)
                captureSession!.startRunning()
            }
        }
    }
}

