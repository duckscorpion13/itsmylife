//
//  MyBuf.swift
//  CollectionView_I
//
//  Created by ChuKoKang on 2017/2/9.
//  Copyright © 2017年 ChuKoKang. All rights reserved.
//

import UIKit
import Photos



class MyMedia{
    var Photolist = [PHAsset]()
    var Videolist = [PHAsset]()
    
    func fetchAllPhotos(){
        self.Photolist.removeAll()
        
        // 從裝置中取得所有類型為圖片的asset
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        for i in 0 ..< fetchResult.count {
            let asset = fetchResult.object(at: i)
            
//            let size = CGSize(width: imageAsset.pixelWidth, height: imageAsset.pixelHeight)
            let size = CGSize(width: 128, height: 128)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .default,
                options: nil,
                resultHandler: { (image, nil) in
                    // 參數 image 即為所取得的圖片
                    self.Photolist.append(asset)
            })
        }
    }
    
    func fetchAllVideos(){
        self.Videolist.removeAll()
        
        // 從裝置中取得所有類型為圖片的asset
        let fetchResult = PHAsset.fetchAssets(with: .video, options: nil)
        for i in 0 ..< fetchResult.count {
            let asset = fetchResult.object(at: i)
            PHImageManager.default().requestPlayerItem(forVideo : asset, options: nil, resultHandler: {(playerItem, nil) in
                self.Videolist.append(asset)
            })
        }
    }
}
