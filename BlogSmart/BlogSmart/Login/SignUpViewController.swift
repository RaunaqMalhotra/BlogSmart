//
//  SignUpViewController.swift
//  BlogSmart
//
//  Created by Michael Dacanay on 4/16/23.
//

import UIKit
import SafariServices

class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var termsCheckBox: UIButton!
    @IBOutlet weak var startBloggingButton: UIButton!
    
    let uncheckedButton = UIImage(systemName: "square")
    let checkedButton = UIImage(systemName: "checkmark.square.fill")
    
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                termsCheckBox.setImage(checkedButton, for: UIControl.State.normal)
                startBloggingButton.backgroundColor = UIColor.systemOrange
                startBloggingButton.isEnabled = true
            } else {
                termsCheckBox.setImage(uncheckedButton, for: UIControl.State.normal)
                startBloggingButton.backgroundColor = UIColor.systemGray
                startBloggingButton.isEnabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        termsLabel.isUserInteractionEnabled = true
    }
    
    
    @IBAction func onStartBloggingDidTap(_ sender: Any) {
        
        guard let username = usernameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !username.isEmpty,
              !email.isEmpty,
              !password.isEmpty else {
            showMissingFieldsAlert()
            return
        }
        
        var newUser = User()
        newUser.username = username
        newUser.email = email
        newUser.password = password
        newUser.blockedUsers = []
        
        newUser.signup { [weak self] result in
            
            switch result {
            case .success(let user):
                print("✅ Successfully signed up user \(user)")
                NotificationCenter.default.post(name: Notification.Name("login"), object: nil)
                
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }
    
    @IBAction func didTapTerms(_ sender: Any) {
        
        let pdfURLString = "https://docs.google.com/document/d/1GaM34KZhNrLTLb6JIpL-PFhHa-fohwHm3JOVUhNGBos"
        
        if let pdfURL = URL(string: pdfURLString) {
            let safariViewController = SFSafariViewController(url: pdfURL)
            present(safariViewController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func didTapTermsCheckbox(_ sender: Any) {
        isChecked = !isChecked
    }
    
    private func showMissingFieldsAlert() {
        let alertController = UIAlertController(title: "Oops...", message: "We need all fields filled out in order to sign you up.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

// Code to dismiss keyboard when tapped on screen
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
