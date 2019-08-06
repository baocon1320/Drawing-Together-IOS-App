//
//  ViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 1/16/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit
import MessageUI
import FirebaseDatabase
import Firebase
import Photos

class ViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    
    // Handle touches (support multitouches)
    var lastPoints = [CGPoint]()
    var currentPoints = [CGPoint]()
    var curTouches = [UITouch : CGPoint]()
    var swipes = [UITouch : Bool]()
    var touchGestures = [UITouch : [Gesture]]()
    var gestures = [Gesture]()
    
    // Handle redo undo button
    var isUndo = false
    var allGestures = [GestureInfo : [Gesture]]()
    var gesturesId = [String]()
    var stackSnap: StackSnapshot!
    var curStack = 0 {
        didSet{
            if stackSnap.stackCur == stackSnap.stackFirst {
                self.undoButton.isEnabled = false
            } else {
                self.undoButton.isEnabled = true
            }
            if stackSnap.stackEnd == stackSnap.stackCur {
                self.redoButton.isEnabled = false
            } else {
                self.redoButton.isEnabled = true
            }
        }
    }
    
    // MARK: Variable for drawing
    var lastPoint = CGPoint.zero
    var greenColor: CGFloat = 0.0
    var redColor: CGFloat = 0.0
    var blueColor: CGFloat = 0.0
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var penSetting: PenInfo?
    var currentCanvas : CanvasDetail?
    
    //Database referene
    var user: User?
    var ref : DatabaseReference!
    var gestureRef : DatabaseReference!
    var canvasRef : DatabaseReference!
    var imageRef : StorageReference!
    
    //Alert and dateformat
    var dateFormatter = DateFormatter()
    var shareAlert : UIAlertController?
    var shareAction : UIAlertAction?
    
    //Check if firstload
    var newLoad = false
    
    // check if this user change background
    var isBgSet = false
    
    // AspectFit Size and begin point of main Image
    var aspectfitSize : CGSize?
    var aspectfitPoint : CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //// Add the tmep image on top of the main image
        mainImageView.addSubview(tempImageView)
        
        // Initial stack of undo/redo
        stackSnap = StackSnapshot()
        let newGestures = [String :Gesture]()
        let newSnapshot = ScreeenSnapshot(currentGestureInfo: nil, gestures: newGestures)
        self.stackSnap.push(newSnapshot: newSnapshot)
        curStack = 0
        
        //innitialize aspectfitSize of main image
        aspectfitSize = CGSize(width: view.frame.width, height: view.frame.height)
        aspectfitPoint = CGPoint(x: 0, y: 0)
        
        //Set dateformat
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        //Load the arlert
        loadAlert()
        
        //Load initial values of pencil
        penSetting = PenInfo(width: brushWidth, green: greenColor, red: redColor, blue: blueColor)
        
        // initialize DB reference
        ref = Database.database().reference()
        gestureRef = ref.child("gesture").child(currentCanvas!.id!)
        canvasRef = ref.child("work").child(currentCanvas!.id!)
        imageRef = Storage.storage().reference().child("images")
        
        loadBackgroundImage()
        
        //trigger delete gesture
        deleteGestures()
    }
    
    // Handle change orientation of device:: Need to implement
    override func viewWillTransition(to: CGSize, with: UIViewControllerTransitionCoordinator) {
        //print(UIDevice.current.orientation)
        if UIDevice.current.orientation.isLandscape {
            print("landscape")
            //getAspectfitValue()
            //reloadAllGestures()
        } else {
            print("portrait")
            //getAspectfitValue()
            //reloadAllGestures()
        }
    }
    
    // Get aspectfit Value of backgound image
    func getAspectfitValue() {
        let mainImageViewSize = self.mainImageView.bounds.size
        if let mainImageSize = self.mainImageView.image?.size {
            var imageFactor = mainImageViewSize.width / mainImageSize.width
            imageFactor = imageFactor < mainImageViewSize.height / mainImageSize.height ? imageFactor : mainImageViewSize.height / mainImageSize.height
            aspectfitSize = CGSize(width: imageFactor*mainImageSize.width, height: imageFactor*mainImageSize.height)
            aspectfitPoint = CGPoint(x: (mainImageViewSize.width - aspectfitSize!.width)/2, y: (mainImageViewSize.height - aspectfitSize!.height)/2)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // initial Load all gesture for the first time
    func loadFirstGesture() {
        let newRef = self.gestureRef.queryOrdered(byChild: "time")
        newRef.observeSingleEvent(of: .value, with: {(groupSnapshot) in
            self.newLoad = true
            for child in groupSnapshot.children {
                self.gestures.removeAll()
                let child = child as! DataSnapshot
                let newGestureInfo = GestureInfo(snapshot: child)
                self.allGestures[newGestureInfo] = [Gesture]()
                let gestureChildRef = self.gestureRef.child(child.key).child("gestures")
                gestureChildRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    for child in snapshot.children {
                        let newGesture = Gesture(snapshot: child as! DataSnapshot)
                        let newFrom_x = newGesture.fromPoint_x * self.aspectfitSize!.width + self.aspectfitPoint!.x
                        let newFrom_y = newGesture.fromPoint_y * self.aspectfitSize!.height + self.aspectfitPoint!.y
                        let newTo_x = newGesture.toPoint_x * self.aspectfitSize!.width + self.aspectfitPoint!.x
                        let newTo_y = newGesture.toPoint_y * self.aspectfitSize!.height + self.aspectfitPoint!.y
                        newGesture.fromPoint_x = newFrom_x
                        newGesture.fromPoint_y = newFrom_y
                        newGesture.toPoint_x = newTo_x
                        newGesture.toPoint_y = newTo_y
                        self.gestures.append(newGesture)
                        self.allGestures[newGestureInfo]?.append(newGesture)
                    }
                    self.drawManyLines(gestures: self.gestures)
                })
            }
        })
    }
    
    // Trigger new gestures from Firebase
    func loadNewGestures() {
        let newRef = self.gestureRef.queryOrdered(byChild: "time")
        newRef.observe(.childAdded, with: { (groupSnapshot) -> Void in
            if !self.newLoad {
                return
            }
            var snapGestures = [String : Gesture]()
            self.gestures.removeAll()
            let newGestureInfo = GestureInfo(snapshot: groupSnapshot)
            self.allGestures[newGestureInfo] = [Gesture]()
            self.gesturesId.append(groupSnapshot.key)
            let childRef = self.gestureRef.child(groupSnapshot.key).child("gestures")
            childRef.observe(.value, with: {snapshot in
                
                // Check if is a undo
                if !snapshot.exists() {
                    //print("deleting")
                    return
                }
                
                for child in snapshot.children {
                    let newGesture = Gesture(snapshot: child as! DataSnapshot)
                    let newFrom_x = newGesture.fromPoint_x * self.aspectfitSize!.width + self.aspectfitPoint!.x
                    let newFrom_y = newGesture.fromPoint_y * self.aspectfitSize!.height + self.aspectfitPoint!.y
                    let newTo_x = newGesture.toPoint_x * self.aspectfitSize!.width + self.aspectfitPoint!.x
                    let newTo_y = newGesture.toPoint_y * self.aspectfitSize!.height + self.aspectfitPoint!.y
                    newGesture.fromPoint_x = newFrom_x
                    newGesture.fromPoint_y = newFrom_y
                    newGesture.toPoint_x = newTo_x
                    newGesture.toPoint_y = newTo_y
                    self.gestures.append(newGesture)
                    self.allGestures[newGestureInfo]?.append(newGesture)
                    snapGestures[newGesture.id!] = newGesture
                }
                
                if(newGestureInfo.editor == self.user!.uid) {
                    let lastSnap = self.stackSnap.items[self.stackSnap.stackCur]
                    if lastSnap?.currentGestureInfo == newGestureInfo {
                        let newScreenSnapshot = ScreeenSnapshot(currentGestureInfo: newGestureInfo, gestures: snapGestures)
                        self.stackSnap.items[self.stackSnap.stackCur] = newScreenSnapshot
                    } else {
                        if(self.isUndo) {
                            return
                        }
                        let newScreenSnapshot = ScreeenSnapshot(currentGestureInfo: newGestureInfo, gestures: snapGestures)
                        self.stackSnap.push(newSnapshot: newScreenSnapshot)
                    }
                    self.curStack = self.stackSnap.stackCur
                    
                    
                } else {
                    self.drawManyLines(gestures: self.gestures)
                }
            })
        })
    }
    
    // Reload All gestures after delete (undo button) sorted by timestamp
    func reloadAllGestures() {
        tempImageView.image = nil
        let sortAllGetsures = allGestures.sorted(by: {
            $0.key.time < $1.key.time
        })
        for gestures in sortAllGetsures {
            drawManyLines(gestures: gestures.value)
        }
    }
    
    //MARK: Delete Gestures --
    func deleteGestures() {
        
        gestureRef.observe(.childRemoved, with: { (snapshot) -> Void in
            self.gestureRef.observeSingleEvent(of: .value, with: { snapshot in
                // Delete All
                if !snapshot.exists() {
                    // Update undo/redo stack
                    let newgestures = [String : Gesture]()
                    self.stackSnap.stackFirst = 0
                    self.stackSnap.stackCur = 0
                    self.stackSnap.stackEnd = 0
                    self.stackSnap.items[0]!.currentGestureInfo = nil
                    self.stackSnap.items[0]!.gestures = newgestures
                    self.curStack = 0
                    return
                }
            })
            let newGestureInfo = GestureInfo(snapshot: snapshot)
            self.allGestures.removeValue(forKey: newGestureInfo)
            self.reloadAllGestures()
        })
    }
    
    //MARK: Load Alert for sharing
    func loadAlert() {
        // Create  Alert
        // Create alert for user entering the detail of new canvas
        shareAlert = UIAlertController(title: "Invite Your Friend to Collaborate", message: "", preferredStyle: .alert)
        let roomId = "roomID: " + currentCanvas!.id!
        let roomKey = "room Key: " +  currentCanvas!.roomkey
        shareAlert!.message = roomId + "\n" + roomKey
        
        // Add Action to Alert
        shareAction = UIAlertAction(title: "Share", style: .default) {(_) in
            self.sendMessage()
        }
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        shareAlert!.addAction(shareAction!)
        shareAlert!.addAction(cancelAction)
    }
    
    // ----------- MARK:  Do Drawing --------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            swipes[touch] = false
            curTouches[touch] = touch.location(in: view)
            touchGestures[touch] = [Gesture]()
        }
    }
    
    func drawLine(gesture : Gesture) {
        UIGraphicsBeginImageContext(view.frame.size)
        tempImageView.image?.draw(in : CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        if let context = UIGraphicsGetCurrentContext() {
            context.move(to: CGPoint(x: gesture.fromPoint_x, y : gesture.fromPoint_y));
            context.addLine(to: CGPoint(x: gesture.toPoint_x, y: gesture.toPoint_y));
            context.setLineCap(CGLineCap.round);
            context.setLineWidth(gesture.penInfo.width);
            context.setStrokeColor(red: gesture.penInfo.red, green: gesture.penInfo.green, blue: gesture.penInfo.blue, alpha: 1.0);
            context.setBlendMode(CGBlendMode.normal);
            context.strokePath();
        }
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    func drawManyLines(gestures : [Gesture]) {
        UIGraphicsBeginImageContext(view.frame.size)
        tempImageView.image?.draw(in : CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        if let context = UIGraphicsGetCurrentContext() {
            for gesture in gestures {
                context.move(to: CGPoint(x: gesture.fromPoint_x, y : gesture.fromPoint_y));
                context.addLine(to: CGPoint(x: gesture.toPoint_x, y: gesture.toPoint_y));
                context.setLineCap(CGLineCap.round);
                context.setLineWidth(gesture.penInfo.width);
                context.setStrokeColor(red: gesture.penInfo.red, green: gesture.penInfo.green, blue: gesture.penInfo.blue, alpha: 1.0);
                context.setBlendMode(CGBlendMode.normal);
                
                context.strokePath();
            }
        }
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let newLocation = touch.location(in: view)
            let newGesture = Gesture(fromPoint_x: curTouches[touch]!.x, fromPoint_y: curTouches[touch]!.y, toPoint_x: newLocation.x, toPoint_y: newLocation.y, penInfo: penSetting!)
            drawLine(gesture: newGesture)
            touchGestures[touch]!.append(newGesture)
            curTouches[touch] = newLocation
            swipes[touch] = true
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // For just a point
            if !swipes[touch]! {
                let newGesture = Gesture(fromPoint_x: curTouches[touch]!.x, fromPoint_y: curTouches[touch]!.y, toPoint_x: curTouches[touch]!.x, toPoint_y: curTouches[touch]!.y, penInfo: penSetting!)
                touchGestures[touch]!.append(newGesture)
                drawLine(gesture: newGesture)
            }
        }
        
        for touch in touches {
            let newGestureSetRef = self.gestureRef?.childByAutoId()
            let newGestureInfo = [
                "time" : ServerValue.timestamp(),
                "editor" : user!.uid
                ] as [String : Any]
            newGestureSetRef?.setValue(newGestureInfo)
            isUndo = false
            for gesture in touchGestures[touch]! {
                let newGestureRef = newGestureSetRef?.child("gestures").childByAutoId()
                let newFrom_x = (gesture.fromPoint_x - self.aspectfitPoint!.x)/self.aspectfitSize!.width
                let newFrom_y = (gesture.fromPoint_y - self.aspectfitPoint!.y)/self.aspectfitSize!.height
                let newTo_x = (gesture.toPoint_x - self.aspectfitPoint!.x)/self.aspectfitSize!.width
                let newTo_y = (gesture.toPoint_y - self.aspectfitPoint!.y)/self.aspectfitSize!.height
                gesture.fromPoint_x = newFrom_x
                gesture.fromPoint_y = newFrom_y
                gesture.toPoint_x = newTo_x
                gesture.toPoint_y = newTo_y
                newGestureRef?.setValue(gesture.toAnyObject())
                self.canvasRef!.child("lastEdited").setValue(dateFormatter.string(from: Date()))
            }
        }
    }
    
    /*
     End of Drawing
     */
    
    //MFMessage Delegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            dismiss(animated: true, completion: nil)
            print("message cancelled \n")
        case .failed:
            dismiss(animated: true, completion: nil)
            print("message failed \n")
        case .sent:
            dismiss(animated: true, completion: nil)
            print("message sent \n")
        }
    }
    
    // Send Room info by messaging
    func sendMessage() {
        let message = MFMessageComposeViewController()
        message.body = "Join me in White Board: \n r" + shareAlert!.message!
        message.recipients = [""]
        message.messageComposeDelegate = self
        if MFMessageComposeViewController.canSendText() {
            self.present(message, animated: true, completion: nil)
        } else {
            print("This device can not send message")
        }
        
        
    }
    
    // Segue to penEdit
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "penEditSegue") {
            let destination = segue.destination as? penInfoViewController
            destination?.penCurrentInfo = penSetting
        } 
    }
    
    // Unwind Segue
    @IBAction func unwindToDrawingBoard(sender : UIStoryboardSegue){
        if let sourceViewController =  sender.source as? penInfoViewController, let newSetting = sourceViewController.newPenSetting {
            penSetting = newSetting
            
        }
    }
    
    //MARK: Exit button
    @IBAction func ReturnToMainTable(_ sender: UIButton) {
    }
    
    
    //MARK: Share button
    @IBAction func shareCanvas(_ sender: UIButton) {
        self.present(shareAlert!, animated: true, completion: nil)
    }
    
    //MARK: Delete Button
    @IBAction func removeAllButton(_ sender: UIButton) {
        gestureRef.removeValue()
        allGestures.removeAll()
        reloadAllGestures()
    }
    
    @IBAction func getPhoto(_ sender: UIButton) {
        
        let phActionsheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        phActionsheet.addAction(UIAlertAction(title: "Camera", style: .default) { (_) in
            self.takePhoto()
        })
        
        phActionsheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { (_) in
            self.getPhoto()
        })
        
        phActionsheet.addAction(UIAlertAction(title: "Blank Image", style: .default) { (_) in
            self.blankImage()
        })
        
        phActionsheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        // Popover to make action sheet work on Ipad
        phActionsheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        phActionsheet.popoverPresentationController?.permittedArrowDirections = []
        phActionsheet.popoverPresentationController?.sourceView = self.view
        
        present(phActionsheet, animated: true, completion: nil)
        
    }
    
    
    // Save Image to library
    @IBAction func saveImage(_ sender: UIButton) {
        
        UIGraphicsBeginImageContext(view.frame.size)
        mainImageView.image?.draw(in : CGRect(x: aspectfitPoint!.x, y: aspectfitPoint!.y, width: aspectfitSize!.width, height: aspectfitSize!.height))
        tempImageView.image?.draw(in : CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        let saveImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let shareActivity = UIActivityViewController(activityItems: [saveImage], applicationActivities: nil)
        shareActivity.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
        shareActivity.popoverPresentationController?.permittedArrowDirections = []
        shareActivity.popoverPresentationController?.sourceView = self.view
        present(shareActivity, animated: true)
    }
    
    // Undo button
    @IBAction func undoButton(_ sender: UIButton) {
        if let lastSnapshot = stackSnap.undo() {
            gestureRef.child((lastSnapshot.currentGestureInfo?.id)!).removeValue()
            self.canvasRef!.child("lastEdited").setValue(dateFormatter.string(from: Date()))
        }
        curStack = stackSnap.stackCur
    }
    
    // Redo button
    @IBAction func redo(_ sender: UIButton) {
        if let nextSnapshot = stackSnap.redo() {
            isUndo = true
            drawManyLines(gestures: Array(nextSnapshot.gestures.values))
            let newGestureSetRef = self.gestureRef.childByAutoId()
            nextSnapshot.currentGestureInfo?.id  = newGestureSetRef.key!
            for gesture in nextSnapshot.gestures.values {
                let newFrom_x = (gesture.fromPoint_x - self.aspectfitPoint!.x)/self.aspectfitSize!.width
                let newFrom_y = (gesture.fromPoint_y - self.aspectfitPoint!.y)/self.aspectfitSize!.height
                let newTo_x = (gesture.toPoint_x - self.aspectfitPoint!.x)/self.aspectfitSize!.width
                let newTo_y = (gesture.toPoint_y - self.aspectfitPoint!.y)/self.aspectfitSize!.height
                gesture.fromPoint_x = newFrom_x
                gesture.fromPoint_y = newFrom_y
                gesture.toPoint_x = newTo_x
                gesture.toPoint_y = newTo_y
            }
            let newDic = nextSnapshot.gestures.mapValues{(value) in (value.toAnyObject())}
            newGestureSetRef.setValue(nextSnapshot.currentGestureInfo?.toAnyObject())
            newGestureSetRef.child("gestures").setValue(newDic)
            self.canvasRef!.child("lastEdited").setValue(dateFormatter.string(from: Date()))
        }
        curStack = stackSnap.stackCur
    }
    
}

// Extensiton for picker a new background image
extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            fatalError("info not image")
        }
        mainImageView.image = image
        picker.dismiss(animated: true, completion: nil)
        getAspectfitValue()
        uploadImage()
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    
    //MARK: Functions
    //Take a new picture for background
    func takePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // Get a photo from photo library
    func getPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // Blank Image for background
    func blankImage() {
        mainImageView.image = nil
        let oldURL = self.currentCanvas?.backgroundUrl
        if oldURL != "Null" {
            let oldImageRef = self.imageRef.child((self.currentCanvas?.imagePath)!)
            oldImageRef.delete { error in
                if let error = error {
                    print("delete image error \(error)")
                } else {
                    print("delete image success")
                }
            }
        }
        self.canvasRef.updateChildValues(["backgroundUrl" : "Null"])
        {
            error, databaseRef in
            if let error = error {
                print("Error when update url to databse \(error)")
            }
            else {
                print("Image URL update success")
                self.canvasRef.updateChildValues(["imagePath" : "Null"])
                self.currentCanvas?.backgroundUrl = "Null"
                self.currentCanvas?.imagePath = "Null"
                self.canvasRef!.child("lastEdited").setValue(self.dateFormatter.string(from: Date()))
            }
        }
    }
    
    // Upload Image to Firebase
    func uploadImage() {
        guard let curImage = mainImageView.image else {
            return
        }
        let imageData = curImage.jpegData(compressionQuality: 1.0)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imagePath = currentCanvas!.id! + ".jpeg"
        let curImageRef = imageRef.child(imagePath)
        self.getAspectfitValue()
        
        //Upload
        curImageRef.putData(imageData!, metadata : metadata) { (metadata, error) in
            if let error = error {
                print("Error upload image \(error)")
                return
            } else {
                self.isBgSet = true
                
                // Get URL and update to database
                curImageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        print("error geting image url \(String(describing: error))")
                        return
                    }
                    print(downloadURL.absoluteString)
                    
                    let oldURL = self.currentCanvas?.backgroundUrl
                    if oldURL != "Null" {
                        let oldImageRef = self.imageRef.child((self.currentCanvas?.imagePath)!)
                        oldImageRef.delete { error in
                            if let error = error {
                                print("delete image error \(error)")
                            } else {
                                print("delete image success")
                            }
                        }
                    }
                    
                    self.canvasRef.updateChildValues(["backgroundUrl" : downloadURL.absoluteString])
                    {
                        error, databaseRef in
                        if let error = error {
                            print("Error when update url to databse \(error)")
                        }
                        else {
                            self.canvasRef.updateChildValues(["imagePath" : imagePath])
                            self.currentCanvas?.backgroundUrl = downloadURL.absoluteString
                            self.currentCanvas?.imagePath = imagePath
                            self.canvasRef!.child("lastEdited").setValue(self.dateFormatter.string(from: Date()))
                            print("Image URL update success")
                        }
                    }
                    print("Upload success")
                }
                
            }
        }
    }
    
    func loadBackgroundImage() {
        let backgroundRef = canvasRef.child("backgroundUrl")
        backgroundRef.observe(.value, with: {(snapshot) -> Void in
            if let url = snapshot.value as? String {
                //print("URL is " + url)
                if url != "Null" && !self.isBgSet {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let urlDown = URL(string: url)
                        let responseData = try? Data(contentsOf: urlDown!)
                        let downloadImage = UIImage(data: responseData!)
                        DispatchQueue.main.async {
                            self.mainImageView.image = downloadImage
                            self.getAspectfitValue()
                            self.loadNewGestures()
                            self.loadFirstGesture()
                        }
                        //print("change Background")
                    }
                } else {
                    if url == "Null" {
                        self.currentCanvas?.backgroundUrl = "Null"
                        self.currentCanvas?.imagePath = "Null"
                        self.mainImageView.image = nil
                        self.loadNewGestures()
                        self.loadFirstGesture()
                        
                        
                    }
                    self.isBgSet = false
                }
            }
        })
    }
    
    
}

