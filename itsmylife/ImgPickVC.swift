//
//  ImgPickVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/23.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import CoreImage


class ImgPickVC: UIViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate  ,UIScrollViewDelegate{

    @IBOutlet weak var sclView: UIScrollView!
    
    @IBAction func btnClick(_ sender: Any) {
        newIPVC()
    }
    var imgView: UIImageView?
    let imagePickerVC = UIImagePickerController()
    func newIPVC() {
        
        // 設定相片的來源為行動裝置內的相本
        imagePickerVC.sourceType = .photoLibrary
        imagePickerVC.delegate = self
        
        // 設定顯示模式為popover
        imagePickerVC.modalPresentationStyle = .popover
        let popover = imagePickerVC.popoverPresentationController
        // 設定popover視窗與哪一個view元件有關連
        popover?.sourceView = self.view
        
        // 以下兩行處理popover的箭頭位置
        popover?.sourceRect = self.view.bounds
        popover?.permittedArrowDirections = .any
        
        show(imagePickerVC, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sclView.delegate=self
        // Do any additional setup after loading the view.
        
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
//        imgView?.image=image
        dismiss(animated: true){
            if let vc=self.storyboard?.instantiateViewController(withIdentifier: "SVC") as? ScrollVC{
                vc.m_img=image
                self.show(vc, sender: self)
            }
        }
//        self.sclView.contentSize = image.size;
//        
//        self.imgView=UIImageView(image:image)
//        self.imgView?.contentMode = .scaleAspectFill
//        self.sclView.addSubview(self.imgView!)
//        detect(self.imgView!.image!,imgViewSize: (self.imgView?.bounds.size)!)
//        dismiss(animated: true, completion: nil)
    }
   

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func getImageSizeAfterAspectFit(_ imgView:UIImageView) -> CGSize {
        guard imgView.image != nil else {
            return CGSize(width: 0, height: 0)
        }
        
        let widthRatio = imgView.bounds.size.width / imgView.image!.size.width
        let heightRatio = imgView.bounds.size.height / imgView.image!.size.height
        
        let scale = (widthRatio >= heightRatio) ? heightRatio : widthRatio
        let imageWidth = scale * imgView.image!.size.width
        let imageHeight = scale * imgView.image!.size.height
        
        return CGSize(width: imageWidth, height: imageHeight)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }

    
    func detect(_ img: UIImage,imgViewSize size:CGSize) {
        
        guard let personciImage = CIImage(image: img) else {
            return
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage)
        
        // Convert Core Image Coordinate to UIView Coordinate
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        for face in faces as! [CIFaceFeature] {
            
            print("Found bounds are \(face.bounds)")
            
            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = size
            let scale = min((viewSize.width) / ciImageSize.width,
                            (viewSize.height) / ciImageSize.height)
            let offsetX = ((viewSize.width) - ciImageSize.width * scale) / 2
            let offsetY = ((viewSize.height) - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceBox = UIView(frame: faceViewBounds)
            
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            self.imgView?.addSubview(faceBox)
            
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
