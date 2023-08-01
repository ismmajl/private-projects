//
//  CameraManager.swift
//  upbike

import UIKit
import AVFoundation
import Photos


//MARK: - Image Picker
class CameraManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static let shared = CameraManager()
    
    private var tweet: Tweet = .main
    private var parentController: UIViewController = UIViewController()
    private let imagePicker = UIImagePickerController()
    
    override init() {
        super.init()
        
        imagePicker.delegate = self
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.allowsEditing = false
    }
    
    func pickMedia(parentController: UIViewController, tweet: Tweet) {
        self.parentController = parentController
        self.tweet = tweet
        
        let camera = "RideDetails.alert.Camera".localized()
        let gallery = "RideDetails.alert.Gallery".localized()
        let controller = ActionSheetController.create(items: [camera, gallery])
        controller.didPressItem = { [self] item in
            if item == camera {
                checkCameraPermission()
            }
            if item == gallery {
                checkGalleryPermission()
            }
        }
        self.parentController.showModal(controller)
    }
    
    //MARK: - Permissions
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:   dispatch { self.openCamera() }
        case .denied:       dispatch { self.warningAlert(isCamera: true) }
        case .notDetermined, .restricted:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                dispatch { granted ? self.openCamera() : self.warningAlert(isCamera: true) }
            })
        @unknown default:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                dispatch { granted ? self.openCamera() : self.warningAlert(isCamera: true) }
            })
        }
    }

    private func checkGalleryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited: dispatch { self.openGallery() }
        case .denied, .restricted:  dispatch { self.warningAlert() }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized, .limited: dispatch { self.openGallery() }
                case .denied, .restricted:  dispatch { self.warningAlert() }
                default:                    break
                }
            }
        @unknown default: break
        }
    }
    
    //MARK: - Open Picker
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            self.parentController.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.parentController.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            //imageViewPic.contentMode = .scaleToFill
            Bird.tweet(name: self.tweet, object: image)
            //images.append(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Waring Alert
    private func warningAlert(isCamera: Bool = false) {
        let message = "RideDetails.alert.CameraWarning".localized() + (isCamera ? "RideDetails.alert.Camera".localized() : "RideDetails.alert.Gallery".localized())
        let alert  = UIAlertController(title: "General.action.Warning".localized(), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "General.action.OK".localized(), style: .default, handler: { alert in
                if let url = NSURL(string:UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
        }))
        self.parentController.present(alert, animated: true, completion: nil)
    }
}
