//
//  UserInfoViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/27/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase


class UserInfoViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var UsernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var oldPassTextField: UITextField!
    @IBOutlet weak var newPassTextField: UITextField!
    @IBOutlet weak var newPassRepeatTextField: UITextField!
    @IBOutlet weak var changePassButton: UIButton!
    
    var userEmail: String?
    var userName: String?
    var ref : DatabaseReference!
    var oldPass : String?
    var newPass : String?
    var repeatNewPass : String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpdatePassButton()
        oldPassTextField.delegate = self
        newPassTextField.delegate = self
        newPassRepeatTextField.delegate = self
        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        
        //Get the userInfo
        Auth.auth().addIDTokenDidChangeListener(){
            auth, user in
            if let user = user {
                self.userEmail = user.email
                self.emailLabel.text = user.email
                self.ref.child("user").child(user.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                    let value = snapshot.value as? NSDictionary
                    self.userName = value?["name"] as? String ?? ""
                    self.UsernameLabel.text = self.userName
                })
            }
        }
    }
    
    //Set title for tabBar
    override func awakeFromNib() {
        self.tabBarItem.title = "User"
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // UITextFiled Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == oldPassTextField {
            self.oldPassTextField.resignFirstResponder()
            self.newPassTextField.becomeFirstResponder()
            
        } else if textField == newPassTextField {
            self.newPassTextField.resignFirstResponder()
            self.newPassRepeatTextField.becomeFirstResponder()
        } else if textField == newPassRepeatTextField {
            self.newPassRepeatTextField.resignFirstResponder()
            if changePassButton.isEnabled {
                changePassword()
            }
            
            
        }
        return true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setUpdatePassButton()
    }
    
    
    //MARK: Functions
    func setUpdatePassButton() {
        oldPass = oldPassTextField.text ?? ""
        newPass = newPassTextField.text ?? ""
        repeatNewPass =  newPassRepeatTextField.text ?? ""
        changePassButton.isEnabled = (!oldPass!.isEmpty && !newPass!.isEmpty && !repeatNewPass!.isEmpty)
    }
    
    func changePassword() {
        oldPass = oldPassTextField.text ?? ""
        newPass = newPassTextField.text ?? ""
        repeatNewPass =  newPassRepeatTextField.text ?? ""
        if newPass != repeatNewPass {
            let alert = UIAlertController(title: "Change pass Error", message: "New pass not same", preferredStyle: .alert)
            let action = UIAlertAction(title: "Got it", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        } else {
            
            let user = Auth.auth().currentUser
            let credential = EmailAuthProvider.credential(withEmail: userEmail!, password: oldPass!)
            user?.reauthenticateAndRetrieveData(with: credential, completion: {(authResult, error) in
                if let _ = error {
                    // An error happened.
                    let alert = UIAlertController(title: "Change Pass Error", message: "Current Pass Not Correct", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Got it", style: .default)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }else{
                    // User re-authenticated.
                    user?.updatePassword(to: self.newPass!) { error in
                        if let error = error {
                            let alert = UIAlertController(title: "Change Pass Error", message: error.localizedDescription, preferredStyle: .alert)
                            let action = UIAlertAction(title: "Got it", style: .default)
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            let alert = UIAlertController(title: "Congratulation", message: "Change Pass Success", preferredStyle: .alert)
                            let action = UIAlertAction(title: "Got it", style: .default)
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                            self.oldPassTextField.text = ""
                            self.newPassTextField.text = ""
                            self.newPassRepeatTextField.text = ""
                        }
                    }
                }
            })
        }
    }
    
    //MARK: Actions
    @IBAction func changePass(_ sender: UIButton) {
        changePassword()
    }
}
