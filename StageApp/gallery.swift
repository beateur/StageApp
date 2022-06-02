//
//  gallery.swift
//  StageApp
//
//  Created by Bilel Hattay on 30/05/2022.
//

import AVFoundation
import SwiftUI
import MobileCoreServices

class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @Binding var image: UIImage?
    @Binding var dismiss: Int

    init(image: Binding<UIImage?>, dismiss: Binding<Int>) {
        _image = image
        _dismiss = dismiss
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
          // Handle image selection result
          print("Selected media is image")

            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                image = uiImage
                dismiss = 0
            }

        case kUTTypeMovie:
          // Handle video selection result
            if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                print("video url; \(videoUrl)")
            }
          
        default:
          print("Mismatched type: \(mediaType)")
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss = 0
    }
    
}

struct ImagePicker: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIImagePickerController
    typealias Coordinator = ImagePickerCoordinator
    
    @Binding var image: UIImage?
    @Binding var dismiss: Int
        
    var sourceType: UIImagePickerController.SourceType = .savedPhotosAlbum
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> ImagePicker.Coordinator {
        return ImagePickerCoordinator(image: $image, dismiss: $dismiss)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = [UTType.image.identifier, UTType.video.identifier]
        picker.delegate = context.coordinator
        return picker
        
    }
    
}
