//
//  FaceCaptureViewController.swift
//  acessobio-iosframe
//
//  Created by Daniel Zanelatto on 09/04/19.
//  Copyright © 2019 Daniel Zanelatto. All rights reserved.
//

import UIKit

import AVFoundation

class FaceCaptureViewController: UIViewController {
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frame: UIImageView?
    var face : UIImageView?
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.photo
        
        let backCamera =  AVCaptureDevice.default(for: AVMediaType.video)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera!)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey:  AVVideoCodecType.jpeg]
            if session!.canAddOutput(stillImageOutput!) {
                session!.addOutput(stillImageOutput!)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity =    AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer!.connection?.videoOrientation =   AVCaptureVideoOrientation.portrait
                self.view.layer.addSublayer(videoPreviewLayer!)
                session!.startRunning()
            }
        }
        
        let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(tapViewCamera(sender:)))
        view.addGestureRecognizer(takePictureTap)
        
        addFaceFrame()
        showToast(message: "Toque na tela para capturar uma foto.")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = self.view.bounds
    }
    
    
    // MARK: - Adicionando frame de captura

    func addFaceFrame() {
        var width: Int
        var height: Int
        
        
        width = Int((1280 / (3.2 / (view.bounds.size.height / 1280))))
        height = Int((720 / (1.40 / (view.bounds.size.width / 720))))
        
        frame = UIImageView(image: UIImage(named: "faceframe.png"))
        // Define o tamanho
        frame!.frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        // Centralize o frame
        frame!.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        view.addSubview(frame!)
    }
    

    // MARK: - Eventos ao tocar na tela

     // MARK:  Toque quando a camêra estiver ativa
    @objc func tapViewCamera(sender: UITapGestureRecognizer) {
        
        self.showToast(message: "Analisando face...")
        self.invokeTakePicture()

    }
     // MARK:  Toque para voltar ao modo de captura
    @objc func tapImageFace(sender: UITapGestureRecognizer) {
        
        self.session?.startRunning()
        
        let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(tapViewCamera(sender:)))
        view.addGestureRecognizer(takePictureTap)

    }
    
    // MARK: - Evento de captura
    
    func invokeTakePicture() {
        
        self.view.isUserInteractionEnabled = false
        
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            stillImageOutput!.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!)!, nil, nil, nil)
                
                let capturedImage = UIImage(data: imageData!) // Imagem capturada
            
                let newImage = capturedImage!.rotate(radians: .pi/180) // Rotacionar a imagem 90 graus
                let base64 = self.getBase64Image(newImage) // Utilizar esse base64 para a validação no WebService
                
                self.face = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
                self.face!.image = capturedImage
                let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(self.tapImageFace(sender:)))
                self.face!.addGestureRecognizer(takePictureTap)
               // self.view.addSubview(self.face!)
                self.session?.stopRunning()
                
                if(base64?.count != nil) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showToast(message: "Base64 pronto!")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showToast(message: "Toque na tela para voltar ao modo captura.")
                            
                            let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(self.tapViewCamera(sender:)))
                            self.view.removeGestureRecognizer(takePictureTap)
                            let takeView = UITapGestureRecognizer(target: self, action: #selector(self.tapImageFace(sender:)))
                            self.view!.addGestureRecognizer(takeView)
                            
                            self.view.isUserInteractionEnabled = true
                            
                            
                        }
                        
                    }
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showToast(message: "Erro ao gerar base64")
                    
                    }
                }

                
            }
        }
        
    }
    
    // MARK: - Utils
    // MARK:  Gerar base64 de imagem PNG ou JPEG
    func getBase64Image(_ image: UIImage?) -> String? {
        var base64Image: String? = nil
        
        defer {
        }
        do {
            var imageData: Data?
            if image?.size.width == 480 {
                imageData = image?.jpegData(compressionQuality: 1.0)
            } else {
                imageData = image?.jpegData(compressionQuality: 0.8)
            }
            
            base64Image = imageData?.base64EncodedString(options: [])
        } catch let _ {
            
        }
        
        return base64Image
    }
    

    // MARK:  Toast Alerta (apenas para log de status)
    func showToast(message : String) {
        
        let toastContainer = UIView(frame: CGRect())
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 25;
        toastContainer.clipsToBounds  =  true
        
        let toastLabel = UILabel(frame: CGRect())
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font.withSize(12.0)
        toastLabel.text = message
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = 0
        
        toastContainer.addSubview(toastLabel)
        self.view.addSubview(toastContainer)
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let a1 = NSLayoutConstraint(item: toastLabel, attribute: .leading, relatedBy: .equal, toItem: toastContainer, attribute: .leading, multiplier: 1, constant: 15)
        let a2 = NSLayoutConstraint(item: toastLabel, attribute: .trailing, relatedBy: .equal, toItem: toastContainer, attribute: .trailing, multiplier: 1, constant: -15)
        let a3 = NSLayoutConstraint(item: toastLabel, attribute: .bottom, relatedBy: .equal, toItem: toastContainer, attribute: .bottom, multiplier: 1, constant: -15)
        let a4 = NSLayoutConstraint(item: toastLabel, attribute: .top, relatedBy: .equal, toItem: toastContainer, attribute: .top, multiplier: 1, constant: 15)
        toastContainer.addConstraints([a1, a2, a3, a4])
        
        let c1 = NSLayoutConstraint(item: toastContainer, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 65)
        let c2 = NSLayoutConstraint(item: toastContainer, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -65)
        let c3 = NSLayoutConstraint(item: toastContainer, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -75)
        self.view.addConstraints([c1, c2, c3])
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.5, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: {_ in
                toastContainer.removeFromSuperview()
            })
        })
    }
    
    
    
    
    
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

