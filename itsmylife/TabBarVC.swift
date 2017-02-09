//
//  TabBarVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/2/9.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import Photos

class TabBarVC: UITabBarController, UITabBarControllerDelegate {
    
    let myMedia=MyMedia()
    override func awakeFromNib() {
        delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is MapVC{
            print("MapVC")
        }
        else if viewController is CollectionVC{
            print("CollectionVC")
        }
        else if viewController is CameraVC{
            print("CameraVC")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
