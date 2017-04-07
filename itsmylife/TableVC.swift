//
//  TableVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/4/7.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation


class TableVC: UIViewController{

    @IBOutlet weak var tableView: UITableView!
    var list = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let fm = FileManager.default
        do {
            let files = try fm.contentsOfDirectory(atPath: NSTemporaryDirectory())
            for file in files{
                if(!file.contains("output")){
                    list.append(file)
                }
            }
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func newAlbum(_ sender: UIButton) {
         newIPVC() 
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

extension TableVC : UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = list[indexPath.row]
        let path = NSTemporaryDirectory() + list[indexPath.row]
        let local = URL(fileURLWithPath: path)
        do{
            let data = try Data(contentsOf: local)
            if let image = UIImage(data: data){
                cell.imageView?.image = image
            }
//            } else {
//                cell.imageView?.image = UIImage(contentsOfFile: "play")
//            }
        } catch {
            print(error)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = NSTemporaryDirectory() + list[indexPath.row]
        let local = URL(fileURLWithPath: path)
        do{
            let data = try Data(contentsOf: local)
            if let image = UIImage(data: data){
                let svc = self.storyboard?.instantiateViewController(withIdentifier: "SVC") as? ScrollVC
                svc?.m_img = image
                self.show(svc!, sender: self)
            } else {
                let avc = AVPlayerViewController()
                avc.player = AVPlayer(url : local)
                self.present(avc, animated: true){
                    avc.player?.play()
                }
            }
        } catch {
            print(error)
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let path = NSTemporaryDirectory() + list[indexPath.row]
        let local = URL(fileURLWithPath: path)
        do{
            let data = try Data(contentsOf: local)
            if let image = UIImage(data: data){
                // 圖片存檔
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                    UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
                }
            }
            tableView.reloadData()
        } catch {
            print(error)
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "↓"
    }
}

extension TableVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    
    
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
