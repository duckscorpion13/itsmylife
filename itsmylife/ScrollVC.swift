//
//  ScrollVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/7.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import CoreImage

class ScrollVC: UIViewController ,UIScrollViewDelegate{
  
    var m_img:UIImage?
  
    @IBAction func longPress(_ sender: Any) {
        for faceBox in self.faceBoxes{
            faceBox.removeFromSuperview()
        }
        self.imgView?.removeFromSuperview()
        // 將imageView大小調整為跟scrollView一樣
        self.imgView?.frame = self.sclView.bounds
        self.imgView?.contentMode = .scaleAspectFit
        // 取得圖片縮小後的長寬
        let size=self.sclView.bounds//getImageSizeAfterAspectFit(self.imgView!)
        // 將imageView的大小調整為圖片大小
        self.imgView?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        // 將scrollView的容器大小調整為imageView大小
        self.sclView.contentSize = (self.imgView?.frame.size)!
        self.sclView.addSubview(self.imgView!)

    }
    @IBOutlet weak var sclView: UIScrollView!
    
    var imgView: UIImageView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let img = self.m_img{
            self.imgView = UIImageView(image:img)
            self.imgView?.contentMode = .scaleAspectFill
            self.sclView.addSubview(self.imgView!)
        }

    }
   
    
    override func viewDidAppear(_ animated: Bool) {

        self.sclView.contentSize = (self.imgView?.image!.size)!;
        detect((self.imgView?.image!)!)

    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
  
    var faceBoxes=[UIView]()
    func detect(_ img: UIImage) {
        
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
            let viewSize = self.imgView?.bounds.size
            let scale = min((viewSize?.width)! / ciImageSize.width,
                            (viewSize?.height)! / ciImageSize.height)
            let offsetX = ((viewSize?.width)! - ciImageSize.width * scale) / 2
            let offsetY = ((viewSize?.height)! - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceBox = UIView(frame: faceViewBounds)
            
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            self.imgView?.addSubview(faceBox)
            
            faceBoxes.append(faceBox)
            
//            if face.hasLeftEyePosition {
//                print("Left eye bounds are \(face.leftEyePosition)")
//            }
//            
//            if face.hasRightEyePosition {
//                print("Right eye bounds are \(face.rightEyePosition)")
//            }
        }
    }

}

