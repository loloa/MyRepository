//
//  ViewController.swift
//  Test1
//
//  Created by Tehila Amran on 16/06/2020.
//  Copyright © 2020 None. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices


class BottomView: UIView {
    
    @IBOutlet weak var leftImgView: UIImageView!
    @IBOutlet weak var rightImgView: UIImageView!
    @IBOutlet weak var capture: UIButton!
    
    func convigure(images: [UIImage?]) {
        
        self.isHidden = false
        self.leftImgView.image = images[0]
        self.rightImgView.image = images[1]
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var combinedImageView: UIImageView!
    let sourceUrl = "https://y0.com/cdn2/test/images.json?f"
    var chosenImg: UIImage?
    var previewOverlay: UIImageView?

    lazy var picker: UIImagePickerController = { [unowned self] in

        let imgPicker = UIImagePickerController()
        imgPicker.delegate = self
        imgPicker.sourceType = .camera
        imgPicker.mediaTypes = [kUTTypeImage as String]
        imgPicker.allowsEditing = true
        imgPicker.showsCameraControls = false

        let screenSize:CGSize = UIScreen.main.bounds.size
        let ratio:CGFloat = 4.0 / 3.0
        let cameraHeight:CGFloat = screenSize.width * ratio
        let scale:CGFloat = screenSize.height / cameraHeight
        imgPicker.cameraViewTransform = CGAffineTransform(translationX: 0, y: (screenSize.height - cameraHeight) / 2.0)
        imgPicker.cameraViewTransform = imgPicker.cameraViewTransform.scaledBy(x: scale, y: scale)
        return imgPicker
    }()
    @IBOutlet weak var bottomView: BottomView!{
        didSet{
            self.bottomView.isHidden = true
        }
    }

    @IBOutlet weak var spinner: UIActivityIndicatorView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
     //MARK: -- IBActions

    @IBAction func startTapped(_ sender: UIButton) {
        
        sender.isEnabled = false
        self.spinner.stopAnimating()
        self.spinner.isHidden = false
        
        let provider = SourceProvider.sharedProvider
        provider.downloadSource(url: sourceUrl) { [weak self] (finished) in
            
            guard let bself = self else{
                return
            }
            DispatchQueue.main.async {
                if finished == true {
                    bself.spinner.stopAnimating()
                    sender.isEnabled = true
                    bself.showCamera()
                }
            }
        }
    }

    
    @IBAction func captureTapped(_ sender: UIButton) {
        self.picker.takePicture()
    }
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {

        if sender.view == self.bottomView.leftImgView {
            self.chosenImg = self.bottomView.leftImgView.image

        }else if sender.view == self.bottomView.rightImgView {
            self.chosenImg = self.bottomView.rightImgView.image
         }

        if let previewOverlay = self.previewOverlay {
            previewOverlay.image = self.chosenImg
        }
    }
}



extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    private func checkPermission(callback: @escaping ( (_ allowed: Bool) -> ())) {
        
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied:
            
            callback (false)
        case .authorized:
            callback (true)
        case .restricted:
            callback (false)
            
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                
                if granted {
                    print("Granted access to \(cameraMediaType)")
                    callback (true)
                } else {
                    print("Denied access to \(cameraMediaType)")
                    callback (false)
                }
            }
        }
    }
    
    func showCamera()  {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            
            
            self.checkPermission { [weak self] (allowed) in

                 guard let bself = self else {return}
                
                if allowed == true {
                    
                    DispatchQueue.main.async {

                        bself.present(bself.picker, animated: true) {
                            
                            bself.bottomView.convigure(images: SourceProvider.sharedProvider.images)
                            let frame = bself.picker.view.frame
                            
                            bself.bottomView.frame = CGRect(x: 0, y: frame.size.height - bself.bottomView.frame.size.height, width: frame.size.width, height: bself.bottomView.frame.size.height)

                            let overlay = UIView(frame: frame)
                            overlay.backgroundColor = .clear

                            let previewImgView = UIImageView(frame: frame)
                            previewImgView.alpha = 0.3

                            previewImgView.contentMode = .scaleAspectFill
                            overlay.addSubview(previewImgView)
                            overlay.addSubview(bself.bottomView)
                            bself.previewOverlay = previewImgView
                            bself.picker.cameraOverlayView = overlay
                        }
                    }

                }else {

                    let ac = UIAlertController(title: "Sorry", message: "Access denied", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    bself.present(ac, animated: true)
                    
                }
            }
        }
        
    }
    //MARk: ------ UIImagePickerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // to save reference
        self.view.addSubview(self.bottomView)
        self.bottomView.isHidden = true

        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{

            if self.chosenImg == nil {
                self.chosenImg = self.bottomView.leftImgView.image
            }

            if let imageData = ImagesHandler.blendImages(pickedImage, self.chosenImg){
                 if let image = UIImage(data: imageData){
                    self.combinedImageView.image = image
                    self.save(img: image)

                }
             }
         }

        picker.dismiss(animated: true, completion: nil)

    }

//MARK:  --- Saving Images to album

    func save(img: UIImage) {
           UIImageWriteToSavedPhotosAlbum(img, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
       }

       //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
           if let error = error {
               // we got back an error!
               let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "OK", style: .default))
               present(ac, animated: true)
           } else {
               let ac = UIAlertController(title: "Saved!", message: "Your combined image has been saved to your photos.", preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "OK", style: .default))
               present(ac, animated: true)
           }
       }
 

}

