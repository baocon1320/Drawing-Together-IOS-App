//
//  RegisterViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/6/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextfield: UITextField!
    
    @IBOutlet weak var passwordTextfield: UITextField!
    
    @IBOutlet weak var repeatPasswordTextfiled: UITextField!
    
    @IBOutlet weak var nickNameTextfield: UITextField!
    
    var ref : DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        setRegisterButton()
        disRegister()
    }
    
    
    //MARK: Actions
    
    @IBAction func registerNewUser(_ sender: UIButton) {
        registering()
    }
    
    @IBAction func cancelCreateUser(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    private func registering() {
        let email = emailTextfield.text ?? ""
        let password = passwordTextfield.text ?? ""
        let repeatPassword = repeatPasswordTextfiled.text ?? ""
        
        if( password != repeatPassword)
        {
            let alert = UIAlertController(title: "Register Fail", message: "password and repeat password not the same", preferredStyle: .alert)
            let action = UIAlertAction(title: "Got it", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        } else {
            Auth.auth().createUser(withEmail: email, password: password) {
                user, error in
                
                if let error = error, user == nil {
                    let alert = UIAlertController(title: "Register Fail", message: error.localizedDescription, preferredStyle: .alert)
                    let action = UIAlertAction(title: "Got it", style: .default)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
                
                if error == nil {
                    Auth.auth().signIn(withEmail: email, password: password)
                }
            }
        }
    }
    
    private func disRegister(){
        Auth.auth().addStateDidChangeListener(){
            auth, user in
            if user != nil {
                let newUserRef = self.ref.child("user").child(user!.uid)
                let nickName = self.nickNameTextfield.text ?? ""
                newUserRef.updateChildValues(["name" : nickName])
                //self.canvasRef.updateChildValues(["backgroundUrl" : "Null"])
                self.performSegue(withIdentifier: "registerSucceed", sender: nil)
                self.emailTextfield.text = nil
                self.passwordTextfield.text = nil
                self.repeatPasswordTextfiled.text = nil
                self.nickNameTextfield.text = nil
            }
        }
    }
    
    private func setRegisterButton(){
        let email = emailTextfield.text ?? ""
        let password = passwordTextfield.text ?? ""
        let samePassword = repeatPasswordTextfiled.text ?? ""
        let nickName = nickNameTextfield.text ?? ""
        registerButton.isEnabled = (!email.isEmpty && !password.isEmpty && !samePassword.isEmpty && !nickName.isEmpty)
    }
    
    //MARK: UITextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nickNameTextfield {
            self.nickNameTextfield.resignFirstResponder()
            self.emailTextfield.becomeFirstResponder()
            
        } else if textField == emailTextfield {
            self.emailTextfield.resignFirstResponder()
            self.passwordTextfield.becomeFirstResponder()
            
        } else if textField == passwordTextfield {
            self.passwordTextfield.resignFirstResponder()
            self.repeatPasswordTextfiled.becomeFirstResponder()
        } else if textField == repeatPasswordTextfiled {
            self.repeatPasswordTextfiled.resignFirstResponder()
            if registerButton.isEnabled {
                registering()
            }
            
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setRegisterButton()
    }
}
