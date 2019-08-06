//
//  CanvasTableViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/6/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Firebase

class CanvasTableViewController: UITableViewController, UITextFieldDelegate {
    
    //MARK: Properties
    var userEmail : String?
    var uid : String?
    var name : String = "Bao"
    var curCanvas : CanvasDetail?
    var canvasList = [CanvasDetail]()
    var ref : DatabaseReference!
    var ref_User : DatabaseReference!
    var ref_Canvas : DatabaseReference!
    var imageRef : StorageReference!
    
    // Datime format
    var dateFormatter = DateFormatter()
    var dayFormatter = DateFormatter()
    var timeFormatter = DateFormatter()
    
    
    var canvasDict : [String : CanvasDetail] = [:]
    var createCanvasAlert : UIAlertController?
    var enterCanvasAlert : UIAlertController?
    var isDeleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isToolbarHidden = false
        //DateFormatter
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dayFormatter.dateFormat = "yyyy-MM-dd"
        timeFormatter.dateFormat = "HH:mm"
        ref = Database.database().reference()
        imageRef = Storage.storage().reference().child("images")
        
        //Load Alert
        loadNewCanvasAlert()
        loadEnterCanvasAlert()
        
        //TextField Delegate
        createCanvasAlert!.textFields![0].delegate = self
        createCanvasAlert!.textFields![1].delegate = self
        enterCanvasAlert!.textFields![0].delegate = self
        enterCanvasAlert!.textFields![1].delegate = self
        
        
        //Get the user email
        Auth.auth().addIDTokenDidChangeListener() {
            auth, user in
            if let user = user {
                self.userEmail = user.email
                self.uid = user.uid
                
                // Load all the canvas that user have worked on
                self.ref_User = self.ref.child("user").child(user.uid).child("workList")
                self.ref_Canvas = self.ref.child("work")
                self.loadCanvas()
            }
            
        }
    }
    
    // Set title fore tabBar
    override func awakeFromNib() {
        // Set name for title of tabBar
        self.tabBarItem!.title = "Canvases"
        
    }
    
    //MARK: Load New Canvas Alert
    func loadNewCanvasAlert() {
        
        //Create New Canvas Alert
        // Create alert for user entering the detail of new canvas
        createCanvasAlert = UIAlertController(title: "Create New Canvas", message: "Enter Your Canvas Information", preferredStyle: .alert)
        
        // Add textFiled to Alert
        createCanvasAlert!.addTextField{(textField) in textField.placeholder = "Canvas Name"}
        createCanvasAlert!.addTextField{(textField) in textField.placeholder = "Canvas Key"}
        
        // Add Action to Alert
        let enterAction = UIAlertAction(title: "Enter", style: .default) {(_) in
            let roomName = self.createCanvasAlert!.textFields?[0].text ?? ""
            let roomKey = self.createCanvasAlert!.textFields?[1].text ?? ""
            
            // Add to the list of all works in database
            let refNewCanvas = self.ref.child("work").childByAutoId()
            let currentTime = self.dateFormatter.string(from: Date())
            
            let canvas = CanvasDetail(backgroundUrl: "Null", imagePath : "Null", roomkey: roomKey, dateCreated : currentTime, lastEdited : currentTime, title : roomName)
            refNewCanvas.setValue(canvas.toAnyObject())
            
            // Add this user to the users of this canvas
            let refCanvasUsers = refNewCanvas.child("users").child(self.uid!)
            refCanvasUsers.setValue(true)
            
            // Add to the list of current work of this user
            let refUserNewCanvas = self.ref_User.child(refNewCanvas.key!)
            refUserNewCanvas.setValue(true)
            self.curCanvas = canvas
            self.curCanvas!.id = refNewCanvas.key!
            self.performSegue(withIdentifier: "collaborateSegue", sender:self)
            
        }
        
        enterAction.isEnabled = false
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        createCanvasAlert!.addAction(enterAction)
        createCanvasAlert!.addAction(cancelAction)
    }
    
    func loadEnterCanvasAlert() {
        //Main Alert to collaborating a room
        enterCanvasAlert = UIAlertController(title: "Room Login", message: "Enter Room Information", preferredStyle: .alert)
        
        
        // Add textfields to Allert
        enterCanvasAlert!.addTextField{
            (textField) in textField.placeholder = "Enter Room Id"
        }
        
        enterCanvasAlert!.addTextField{
            (textField) in textField.placeholder = "Enter Room Key"
        }
        
        //Enter Action
        let enterAction = UIAlertAction(title: "Enter", style: .default) {(_) in
            let roomId = self.enterCanvasAlert!.textFields?[0].text ?? ""
            let roomKey = self.enterCanvasAlert!.textFields?[1].text ?? ""
            
            let newRef = self.ref_Canvas.child(roomId)
            newRef.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    let canvas = CanvasDetail(snapshot: snapshot)
                    let key = canvas.roomkey
                    
                    if(key != roomKey) {
                        let alert = UIAlertController(title: "Room Login Error", message: "Room key is not correct", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Got it", style: .default)
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        // Add this user to the users of this canvas
                        let refCanvasUsers = newRef.child("users").child(self.uid!)
                        refCanvasUsers.setValue(true)
                        
                        self.curCanvas = canvas
                        let refUserNewCanvas = self.ref_User.child(roomId)
                        refUserNewCanvas.setValue(true)
                        self.performSegue(withIdentifier: "collaborateSegue", sender:self)
                    }
                } else {
                    
                    let alert = UIAlertController(title: "Room Login Error", message: "Room does not exist", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Got it", style: .default)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
        
        enterAction.isEnabled = false
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        enterCanvasAlert!.addAction(enterAction)
        enterCanvasAlert!.addAction(cancelAction)
    }
    
    
    //MARK: TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createCanvasAlert!.textFields?[0].resignFirstResponder()
        createCanvasAlert!.textFields?[1].resignFirstResponder()
        enterCanvasAlert!.textFields?[0].resignFirstResponder()
        enterCanvasAlert!.textFields?[1].resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // Disable the enter Room action when user didn't set the room Name or roomKey
        let roomName = createCanvasAlert!.textFields?[0].text ?? ""
        let roomKey = createCanvasAlert!.textFields?[1].text ?? ""
        createCanvasAlert!.actions[0].isEnabled = (!roomName.isEmpty && !roomKey.isEmpty)
        
        let roomId = enterCanvasAlert!.textFields?[0].text ?? ""
        let roomPass = enterCanvasAlert!.textFields?[1].text ?? ""
        enterCanvasAlert!.actions[0].isEnabled = (!roomId.isEmpty && !roomPass.isEmpty)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return canvasList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CanvasDetailTableViewCell", for: indexPath) as? CanvasDetailTableViewCell
        
        let canvas = canvasList[indexPath.row]
        cell?.canvasTitleLabel.text = canvas.title
        let curDate = dayFormatter.string(from: Date())
        let lastEditDate = dateFormatter.date(from: canvas.lastEdited)
        
        if(curDate == dayFormatter.string(from: lastEditDate!)) {
            cell?.lastEditLabel.text = timeFormatter.string(from: lastEditDate!)
            
        } else {
            cell?.lastEditLabel.text =  dayFormatter.string(from: lastEditDate!)
            
        }
        return cell!
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let canvas = canvasList[indexPath.row]
            
            //Delete user from this canvas
            let refCurrentCanvas = self.ref_Canvas.child(canvas.id!)
            self.ref.child("work").child(canvas.id!).child("imagePath").observeSingleEvent(of: .value, with: {(datashot) in
                print("Delete background \(datashot)")
                let imagePath = datashot.value as! String
                refCurrentCanvas.child("users").child(self.uid!).removeValue()
                // Check if this is only user in this canvas
                // Then remove the canvas entirely and gestures of this
                let newRef = refCurrentCanvas.child("users")
                newRef.observeSingleEvent(of: .value, with: { snapshot in
                    if !snapshot.exists() {
                        refCurrentCanvas.removeValue()
                        self.ref.child("gesture").child(canvas.id!).removeValue()
                        if imagePath != "Null" {
                             let oldImageRef = self.imageRef.child(imagePath)
                             oldImageRef.delete { error in
                             if let error = error {
                             print("delete image error \(error)")
                             } else {
                             print("delete image success")
                             }
                             }
                        }
                        
                    }
                })
                
                //Delete from User
                let refUserCurrentCanvas = self.ref_User.child(canvas.id!)
                refUserCurrentCanvas.removeValue()
                
                self.canvasList.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                
            })
            
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        // Select from one of their canvases
        if(segue.identifier == "showDrawing") {
            let destination = segue.destination as! ViewController
            let selectedIndexPath = self.tableView.indexPathForSelectedRow
            destination.currentCanvas = canvasList[(selectedIndexPath?.row)!]
            destination.user = User(uid: self.uid!, name: self.name, email: self.userEmail!)
        }
            // join a friend's canvas
        else if (segue.identifier == "collaborateSegue") {
            let destination = segue.destination as! ViewController
            destination.currentCanvas = curCanvas!
            destination.user = User(uid: self.uid!, name: self.name, email: self.userEmail!)
        }
        
    }
    
    // Unwind Segue
    @IBAction func unwindToCanvasTable(sender : UIStoryboardSegue){
        if let _ =  sender.source as? ViewController {
            self.navigationController?.isToolbarHidden = false
            //print("hahah")
        }
    }
    
    
    //MARK: Action
    
    @IBAction func LogoutUser(_ sender: UIBarButtonItem) {
        
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            let alert = UIAlertController(title: "Signout fail", message: error.localizedDescription, preferredStyle: .alert)
            let action = UIAlertAction(title: "Got it", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //Load all the canvases that user has worked on
    private func loadCanvas() {
        
        //Load canvas list of this user in fireBase
        ref_User.observe(.value, with: {snapshot in
            self.canvasDict.removeAll()
            for child in snapshot.children {
                
                let canvasId = (child as! DataSnapshot).key
                let newRef = self.ref_Canvas.child(canvasId)
                
                
                
                newRef.observeSingleEvent(of: .value, with: {snapshot in
                    if snapshot.exists() {
                        let canvas = CanvasDetail(snapshot: snapshot)
                        self.canvasDict[canvas.id!] = canvas
                        self.canvasList = Array(self.canvasDict.values)
                        self.canvasList = self.canvasList.sorted(by: { s1, s2 in
                            return self.dateFormatter.date(from: s1.lastEdited)! > self.dateFormatter.date(from: s2.lastEdited)!
                        })
                        self.tableView.reloadData()
                    }
                    
                })
                
                newRef.observe(.childChanged, with: {(snapshot) in
                    
                    
                    if snapshot.key == "lastEdited" {
                        self.canvasDict[canvasId]?.lastEdited = snapshot.value as! String
                        self.canvasList = Array(self.canvasDict.values)
                        self.canvasList = self.canvasList.sorted(by: { s1, s2 in
                            return self.dateFormatter.date(from: s1.lastEdited)! > self.dateFormatter.date(from: s2.lastEdited)!
                        })
                        self.tableView.reloadData()
                    }
                })
                
            }
            
            if(snapshot.childrenCount == 0) {
                self.canvasList = Array(self.canvasDict.values)
                self.canvasList = self.canvasList.sorted(by: { s1, s2 in
                    return s1.lastEdited > s2.lastEdited
                })
                self.tableView.reloadData()
            }
            
            
        })
    }
    
    //Add new canvas
    @IBAction func addNewCanvas(_ sender: UIBarButtonItem) {
        createCanvasAlert!.textFields?[0].text = ""
        createCanvasAlert!.textFields?[1].text = ""
        self.present(createCanvasAlert!, animated: true, completion: nil)
    }
    
    //MARK: Collaborating Button
    @IBAction func collaborating(_ sender: UIBarButtonItem) {
        enterCanvasAlert!.textFields?[0].text = ""
        enterCanvasAlert!.textFields?[1].text = ""
        //Present alert
        self.present(enterCanvasAlert!, animated: true, completion: nil)
    }
    
}
