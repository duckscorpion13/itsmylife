//
//  ViewController.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/7.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
    @IBOutlet weak var imgView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do{
            let urlImg=URL(string:"http://i.imgur.com/Femi2yA.jpg")
            let dataImg=try Data(contentsOf: urlImg!)
            self.imgView.contentMode = .center
            self.imgView.image=UIImage(data: dataImg)
        }catch{
            print("\(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

