//
//  penInfoViewController.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/16/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import UIKit

class penInfoViewController: UIViewController, UINavigationControllerDelegate {
    
    //MARK: Properties
    var penCurrentInfo: PenInfo?
    var newPenSetting: PenInfo?
    @IBOutlet weak var brushSizeSlider: UISlider!
    @IBOutlet weak var redColorSlider: UISlider!
    @IBOutlet weak var greenColorSlider: UISlider!
    @IBOutlet weak var blueColorSlider: UISlider!
    @IBOutlet weak var brushSizeLabel: UILabel!
    @IBOutlet weak var redColorLabel: UILabel!
    @IBOutlet weak var greenColorLabel: UILabel!
    @IBOutlet weak var blueColorLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var setColorButton: UIButton!
    @IBOutlet weak var previewImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the newSetting
        if let setting = penCurrentInfo {
            newPenSetting = PenInfo(width: setting.width, green: setting.green, red: setting.red, blue: setting.blue)
        }
        
        // Set initial value
        if let newPenSetting = newPenSetting {
            setSliders(penInfo: newPenSetting)
            setSliderLabels(penInfo: newPenSetting)
        }
        showPreview()
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIButton else {
            fatalError("The button is not UIButton")
        }
        if button === resetButton {
            newPenSetting = penCurrentInfo
        }
    }
    
    
    //MARK: actions
    func setSliders(penInfo : PenInfo) {
        brushSizeSlider.value = Float((penInfo.width))
        redColorSlider.value = Float((penInfo.red))
        greenColorSlider.value = Float(penInfo.green)
        blueColorSlider.value = Float(penInfo.blue)
    }
    
    func setSliderLabels(penInfo : PenInfo) {
        brushSizeLabel.text = String(Int(penInfo.width))
        redColorLabel.text = String(Int(penInfo.red))
        greenColorLabel.text = String(Int(penInfo.green))
        blueColorLabel.text = String(Int(penInfo.blue))
    }
    
    func showPreview(){
        UIGraphicsBeginImageContext(previewImage.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineCap(CGLineCap.round)
            context.setLineWidth(newPenSetting!.width)
            context.setStrokeColor(red : newPenSetting!.red, green : newPenSetting!.green, blue : newPenSetting!.blue, alpha : 1.0)
            context.move(to: CGPoint(x: 30.0, y: 30.0))
            context.addLine(to: CGPoint(x: 30.0, y: 30.0))
            context.setBlendMode(CGBlendMode.normal)
            context.strokePath()
            
        }
        previewImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    //MARK: Actions Sliders
    @IBAction func brushSizeChange(_ sender: UISlider) {
        let currentValue = Int(brushSizeSlider.value)
        newPenSetting?.width = CGFloat(currentValue)
        brushSizeLabel.text = String(currentValue)
        showPreview()
    }
    
    @IBAction func redColorChange(_ sender: UISlider) {
        let currentValue = Int(redColorSlider.value)
        newPenSetting?.red = CGFloat(currentValue)
        redColorLabel.text = String(currentValue)
        showPreview()
    }
    
    @IBAction func greenColorChange(_ sender: UISlider) {
        let currentValue = Int(greenColorSlider.value)
        newPenSetting?.green = CGFloat(currentValue)
        greenColorLabel.text = String(currentValue)
        showPreview()
    }
    
    @IBAction func blueColorChage(_ sender: UISlider) {
        let currentValue = Int(blueColorSlider.value)
        newPenSetting?.blue = CGFloat(currentValue)
        blueColorLabel.text = String(currentValue)
        showPreview()
    }
    
    

}
