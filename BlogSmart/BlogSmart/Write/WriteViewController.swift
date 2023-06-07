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
        
        // ############################################################
        // Load API key
        guard let keysFileUrl = Bundle.main.url(forResource: "Keys", withExtension: "plist") else {
            fatalError("Couldn't find Keys.plist in the app bundle.")
        }
        guard let keysData = try? Data(contentsOf: keysFileUrl) else {
            fatalError("Couldn't read data from Keys.plist.")
        }
        guard let keys = try? PropertyListSerialization.propertyList(from: keysData, options: [], format: nil) as? [String: Any] else {
            fatalError("Couldn't parse Keys.plist.")
        }
        guard let apiKey = keys["OPENAI_API_KEY"] as? String else {
            fatalError("Couldn't find OPENAI_API_KEY in Keys.plist.")
        }
        
        
        // Create a URL for the request
        // In this case, the custom search URL you created in in part 1
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: endpoint)! as URL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        let json: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": "\(String(describing: blogContent.text)). \nSummarize this in a 3 sentence paragraph."]],
            "temperature": 0.7
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        print("hello")

        // Use the URL to instantiate a request
        request.httpBody = jsonData
        
        // loading icon
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .orange
        view.addSubview(activityIndicator)
        
        // Start animating the activity indicator before the network request starts.
        activityIndicator.startAnimating()

        // Create a URLSession using a shared instance and call its dataTask method
        // The data task method attempts to retrieve the contents of a URL based on the specified URL asynchronously.
        // When finished, it calls it's completion handler (closure) passing in optional values for data (the data we want to fetch), response (info about the response like status code) and error (if the request was unsuccessful)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            // Handle any errors
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
            }

            // Make sure we have data
            guard let data = data else {
                print("❌ Data is nil")
                return
            }

            // The `JSONSerialization.jsonObject(with: data)` method is a "throwing" function (meaning it can throw an error) so we wrap it in a `do` `catch`
            // We cast the resultant returned object to a dictionary with a `String` key, `Any` value pair.
            do {
                let _ = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                // Create a JSON Decoder
                let decoder = JSONDecoder()

                // Use the JSON decoder to try and map the data to our custom model.
                // GPTResponse.self is a reference to the type itself, tells the decoder what to map to.
                let response = try decoder.decode(GPTResponse.self, from: data)

                // Access the array of tracks from the `results` property
                print("✅ \(response.choices[0].message.content)")
                post.summary = response.choices[0].message.content
                
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
                
            } catch {
                print("❌ Error parsing JSON: \(error.localizedDescription)")
            }
        })

        // Initiate the network request
        task.resume()
        // ############################################################

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
