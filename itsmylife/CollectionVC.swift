//
//  ViewController.swift
//  CollectionView_I
//
//  Created by ChuKoKang on 2016/8/1.
//  Copyright © 2016年 ChuKoKang. All rights reserved.
//

import UIKit

class CollectionVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var list = [(String,UIImage?)]()
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    list.append(("AAA",UIImage(named:"003.jpg")))
    list.append(("BBB",UIImage(named:"face-5.jpg")))
    list.append(("CCC",UIImage(named:"face-1.jpg")))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
        cell.label.text = list[indexPath.row].0
        cell.img.image = list[indexPath.row].1
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        print(list[indexPath.row].0)
        if let vc=storyboard?.instantiateViewController(withIdentifier: "SVC"){
            if let svc = vc as? ScrollVC{
                svc.m_img=list[indexPath.row].1
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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

