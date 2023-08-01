//
//  ForgotPasswordController.swift
//  luuria

import UIKit

class ForgotPasswordController: ViewController {
    
    //MARK: - OUTLETS
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var headerTitle: UILabel!

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setTexts()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        UIApplication.shared.statusBarStyle = .lightContent
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.view.alpha = 1.0
            }, completion: nil)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.view.alpha = 0.0
            }, completion: nil)
        }
    }
    @IBAction func leftButtonPressed(_ sender: UIButton) {
        self.pop()
    }
    @IBAction func startButtonPressed(_ sender: UIButton) {
        self.popToRoot()
    }
    @IBAction func resetButtonPressed(_ sender: UIButton) {
         resetPassword()
    }
    func setTexts() {
        topLabel.text = "Enter the email address of your account to receive a link that will allow you to reset your password.".localized
        
        headerTitle.text = "Forgot Password?".localized
        emailTextField.placeholder = "E-Mail".localized
    }
    
    func resetPassword(){
        emailTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, !email.isEmpty else {
            JSSAlertView.show(message: "Email required. Provide an email.".localized)
            return
        }
        if !email.isEmail {
            JSSAlertView.show(message: "Provided email is not valid!".localized)
            return
        }
        
        self.resetButton.showAnimating()
        UserREST.forgotPassword(email: email){ (success, error) in
            self.resetButton.hideAnimating()
            if success {
                JSSAlertView.show(dialog: "Email sent".localized, message: "Go reset password at provided email".localized)
            }
            if let error = error {
                JSSAlertView.show(message: error.message)
            }
        }
    }
}
//MARK: - EXTENSIONS
extension ForgotPasswordController {
    static func create() -> ForgotPasswordController {
        return UIStoryboard.register.instantiate(ForgotPasswordController.self)
    }
}
