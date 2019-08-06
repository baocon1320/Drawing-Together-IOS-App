//
//  LoginViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/6/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var emailTextFiled: UITextField!
    
    @IBOutlet weak var passwordTextFiled: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLoginButton()
        didLogin()
        
        // Do any additional setup after loading the view.
    }
    
    //MARK: action
    @IBAction func Login(_ sender: UIButton) {
        doLogin()
    }
    private func doLogin() {
        let email = emailTextFiled.text ?? ""
        let password = passwordTextFiled.text ?? ""
        
        //Authencication
        Auth.auth().signIn(withEmail: email, password: password) {
            user, error in
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Sign In Error", message: error.localizedDescription, preferredStyle: .alert)
                let action = UIAlertAction(title: "Got it", style: .default)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func didLogin() {
        Auth.auth().addStateDidChangeListener(){
            auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "loginSucceed", sender: nil)
                self.emailTextFiled.text = nil
                self.passwordTextFiled.text = nil
            }
        }
    }
    
    private func setLoginButton(){
        let email = emailTextFiled.text ?? ""
        let password = passwordTextFiled.text ?? ""
        
        LoginButton.isEnabled = (!email.isEmpty && !password.isEmpty)
    }
    
    //MARK TextFiled Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextFiled {
            self.emailTextFiled.resignFirstResponder()
            self.passwordTextFiled.becomeFirstResponder()
            
        } else if textField == passwordTextFiled {
            self.passwordTextFiled.resignFirstResponder()
            if LoginButton.isEnabled {
                doLogin()
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setLoginButton()
    }
}
