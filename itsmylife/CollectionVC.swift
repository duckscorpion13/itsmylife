//
//  CollectionVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/28.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import Photos

class CollectionVC: UIViewController{

    @IBOutlet weak var btn: UIButton!
    var imgView: UIImageView?

    @IBAction func albumClick(_ sender: UIButton) {
        self.newIPVC()
    }
    var m_media: MyMedia?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.m_media?.fetchAllPhotos()

    }

    func fetchAllPhotos() -> [PHAsset]  {
        var images = [PHAsset]()
        
        // 從裝置中取得所有類型為圖片的asset
        let fetchResult = PHAsset.fetchAssets(with: .video, options: nil)
        for i in 0 ..< fetchResult.count {
            let imageAsset = fetchResult.object(at: i)
            
            let size = CGSize(width: imageAsset.pixelWidth, height: imageAsset.pixelHeight)
//            let size = CGSize(width: 128, height: 128)
            PHImageManager.default().requestImage(
                for: imageAsset,
                targetSize: size,
                contentMode: .default,
                options: nil,
                resultHandler: { (image, nil) in
                    // 參數 image 即為所取得的圖片
                    images.append(imageAsset)
            })
        }
        
        return images
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
        return self.m_media?.Photolist.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
        if let pic = self.m_media?.Photolist[indexPath.row]{
            let size = CGSize(width: pic.pixelWidth, height: pic.pixelHeight)
            PHImageManager.default().requestImage(
                for: pic,
                targetSize: size,
                contentMode: .default,
                options: nil,
                resultHandler: { (image, nil) in
                    // 參數 image 即為所取得的圖片
                    cell.img.image = image
                })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        if let vc=storyboard?.instantiateViewController(withIdentifier: "SVC"){
            if let svc = vc as? ScrollVC{
                PHImageManager.default().requestImage(
                    for: (self.m_media?.Photolist[indexPath.row])!,
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

        let imagePickerVC = UIImagePickerController()

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
        self.dismiss(animated: true){
            if let vc=self.storyboard?.instantiateViewController(withIdentifier: "SVC") as? ScrollVC{
                vc.m_img=image
                self.show(vc, sender: self)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

