//
//  CollectionVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/28.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import Photos
import AVKit


class CollectionVC: UIViewController{
    @IBOutlet weak var collectView: UICollectionView!
    @IBOutlet weak var btn: UIButton!
    @IBAction func albumClick(_ sender: UIButton) {
        self.newIPVC()
    }
    var m_media: MyMedia = MyMedia()
    dynamic var m_dataCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObserver(self, forKeyPath: "m_dataCount", options: .new, context: nil)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.collectView.reloadData()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        self.m_media.fetchAllPhotos(type: .video)
        self.m_dataCount = self.m_media.PhotoList.count
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
        return self.m_media.PhotoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
        let pic = self.m_media.PhotoList[indexPath.row]
        let size = CGSize(width: pic.pixelWidth, height: pic.pixelHeight)
        PHImageManager.default().requestImage(
            for: pic,
            targetSize: size,
            contentMode: .default,
            options: nil,
            resultHandler: { (image, nil) in
                // 參數 image 即為所取得的圖片
                cell.img.image = image
                let sec = Int(pic.duration)
                cell.label.text = String(format:"%d:%02d:%02d",sec/3600,sec/60,sec%60)
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        let asset = self.m_media.PhotoList[indexPath.row]
        if(asset.mediaType == .image){
            if let vc=storyboard?.instantiateViewController(withIdentifier: "SVC"){
                if let svc = vc as? ScrollVC{
                    PHImageManager.default().requestImage(
                        for: asset,
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
        else if(asset.mediaType == .video){
            PHImageManager.default().requestPlayerItem(forVideo : asset, options: nil, resultHandler: {(playerItem, nil) in
                let avc = AVPlayerViewController()
                avc.player = AVPlayer(playerItem : playerItem)
                self.present(avc, animated: true){
                    avc.player?.play()
                }
            })
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

