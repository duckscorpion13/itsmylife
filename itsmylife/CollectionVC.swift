//
//  ViewController.swift
//  CollectionView_I
//
//  Created by ChuKoKang on 2016/8/1.
//  Copyright © 2016年 ChuKoKang. All rights reserved.
//

import UIKit
import Photos
import CoreImage

class CollectionVC: UIViewController{

    @IBOutlet weak var btn: UIButton!
    var imgView: UIImageView?
    let imagePickerVC = UIImagePickerController()
    
    @IBAction func albumClick(_ sender: UIButton) {
        self.newIPVC()
    }
    var list: [UIImage]!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        list = fetchAllPhotos()

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

    func fetchAllPhotos() -> [UIImage]  {
        var images = [UIImage]()
        
        // 從裝置中取得所有類型為圖片的asset
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        for i in 0 ..< fetchResult.count {
            let imageAsset = fetchResult.object(at: i)
//            let size = CGSize(width: imageAsset.pixelWidth, height: imageAsset.pixelHeight)
            let size = CGSize(width: 128, height: 128)
            PHImageManager.default().requestImage(
                for: imageAsset,
                targetSize: size,
                contentMode: .default,
                options: nil,
                resultHandler: { (image, nil) in
                    // 參數 image 即為所取得的圖片
                    images.append(image!)
            })
        }
        
        return images
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension CollectionVC : UICollectionViewDataSource, UICollectionViewDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
        cell.img.image = list[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        if let vc=storyboard?.instantiateViewController(withIdentifier: "SVC"){
            if let svc = vc as? ScrollVC{
                let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
                let imageAsset = fetchResult.object(at: indexPath.row)
                PHImageManager.default().requestImage(
                    for: imageAsset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .default,
                    options: nil,
                    resultHandler: { (image, nil) in
                        // 參數 image 即為所取得的圖片
                        svc.m_img=image
                        self.show(svc, sender: self)
                })
            }
        }
    }
}

extension CollectionVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    

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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        //        imgView?.image=image
        dismiss(animated: true){
            if let vc=self.storyboard?.instantiateViewController(withIdentifier: "SVC") as? ScrollVC{
                vc.m_img=image
                self.show(vc, sender: self)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

