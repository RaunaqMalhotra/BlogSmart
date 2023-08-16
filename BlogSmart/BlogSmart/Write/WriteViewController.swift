//
//  WriteViewController.swift
//  BlogSmart
//
//  Created by Michael Dacanay on 4/27/23.
//

import UIKit
import ParseSwift
import PhotosUI

class WriteViewController: UIViewController {
    
    @IBOutlet weak var blogImage: UIImageView!
    @IBOutlet weak var blogTitleField: UITextField!
    @IBOutlet weak var blogContent: UITextView!
    
    private var pickedImage: UIImage?
    
    private var gptResponse: GPTResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Default blog image
        blogImage.image = UIImage(named: "default_image")
        
        // Add border to the UI Text view
        let borderColor = UIColor.black

        blogContent.layer.borderColor = borderColor.cgColor;
        blogContent.layer.borderWidth = 1.0;
        blogContent.layer.cornerRadius = 5.0;
                
        blogTitleField.layer.borderColor = borderColor.cgColor;
        blogTitleField.layer.borderWidth = 1.0;
        blogTitleField.layer.cornerRadius = 5.0;
    }

    
    @IBAction func onChooseImageTapped(_ sender: Any) {
        // Create and configure PHPickerViewController

        // Create a configuration object
        var config = PHPickerConfiguration()

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker
        present(picker, animated: true)
    }
    
    
    @IBAction func onPostTapped(_ sender: Any) {
        // Dismiss Keyboard
        view.endEditing(true)
        
        // Create Post object
        var post = Post()
        
        if pickedImage == nil {
            pickedImage = UIImage(named: "default_image")
        }
        
        // Unwrap optional pickedImage
        guard let image = pickedImage,
              // Create and compress image data (jpeg) from UIImage
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }
        
        // Create a Parse File by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Set properties
        post.imageFile = imageFile
        post.title = blogTitleField.text
        post.content = blogContent.text
        
        // loading icon
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .orange
        view.addSubview(activityIndicator)
        
        // Start animating the activity indicator before the network request starts.
        activityIndicator.startAnimating()
        
        post.summary = blogContent.text
        
        // Set the user as the current user
        post.user = User.current

        // Save post (async)
        post.save { [weak self] result in
            // Switch to the main thread for any UI updates
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")
                    
                    // Get the current user
                    if var currentUser = User.current {
                        
                        // Update the `lastPostedDate` property on the user with the current date.
                        currentUser.lastPostedDate = Date()
                        
                        // Save updates to the user (async)
                        currentUser.save { [weak self] result in
                            switch result {
                            case .success(let user):
                                print("✅ User Saved! \(user)")
                                
                                // Switch to the main thread for any UI updates
                                DispatchQueue.main.async {
                                    activityIndicator.stopAnimating()
                                    
                                    // Return to previous view controller
                                    self?.navigationController?.popViewController(animated: true)
                                    
                                    NotificationCenter.default.post(name: Notification.Name("Go back to the initial screen"), object: nil)
                                }
                                
                            case .failure(let error):
                                self?.showAlert(description: error.localizedDescription)
                            }
                        }
                    }
                    
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
}

extension WriteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Make sure we have a non-nil item provider
        guard let provider = results.first?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }

            // Check for and handle any errors
            if let error = error {
                self?.showAlert(description: error.localizedDescription)
                return
            } else {

                // UI updates (like setting image on image view) should be done on main thread
                DispatchQueue.main.async {

                    // Set image on preview image view
                    self?.blogImage.image = image

                    // Set image to use when saving post
                    self?.pickedImage = image
                }
            }
        }
    }
}
