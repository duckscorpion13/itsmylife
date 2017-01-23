//
//  ViewController.swift
//  CollectionView_I
//
//  Created by ChuKoKang on 2016/8/1.
//  Copyright © 2016年 ChuKoKang. All rights reserved.
//

import UIKit
import Photos

class CollectionVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var list: [UIImage]!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        list = fetchAllPhotos()

    }
    
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
                svc.m_img=list[indexPath.row]
                show(svc, sender: self)
            }
        }
        
    }
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "segue_cvc2svc" {
//            
//            let vc = segue.destination as! ScrollVC
//            vc.img = imgSel
//        }
//    }
    func fetchAllPhotos() -> [UIImage]  {
        var images = [UIImage]()
        
        // 從裝置中取得所有類型為圖片的asset
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        for n in 0 ..< fetchResult.count {
            let imageAsset = fetchResult.object(at: n)
            let size = CGSize(width: imageAsset.pixelWidth, height: imageAsset.pixelHeight)
            
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

