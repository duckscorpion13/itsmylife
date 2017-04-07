//
//  TabBarVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/2/9.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit

extension UIViewController
{
    var contentVC: UIViewController{
        if let nvc = self as? UINavigationController{
            return nvc.visibleViewController!
        } else{
            return self
        }
    }
}

class TabBarVC: UITabBarController, UITabBarControllerDelegate
{
    
    override func awakeFromNib() {
        delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController.contentVC is CameraVC{
            print("CameraVC")
        }else if viewController.contentVC is TableVC{
            print("TableVC")
        }else if viewController.contentVC is MapVC{
            if let mvc = viewController.contentVC as? MapVC{
                mvc.fetchAll()
            }
            print("MapVC")
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
