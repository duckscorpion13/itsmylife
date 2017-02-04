
//
//  ViewController.swift
//  CaptureImage
//
//  Created by ChuKoKang on 2016/8/9.
//  Copyright © 2016年 ChuKoKang. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO

class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, UIScrollViewDelegate {

    // 負責協調從截取裝置到輸出間的資料流動
    let session = AVCaptureSession()
    // 負責即時預覽目前相機設備截取到的畫面
    let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    // 前置鏡頭
    var frontCameraDevice: AVCaptureDeviceInput?
    // 後置鏡頭
    var backCameraDevice: AVCaptureDeviceInput?

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var sclView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var myView: UIView?
    
    override func viewWillAppear(_ animated: Bool) {
        session.startRunning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string:searchBar.text!)
        let quest = URLRequest(url: url!)
        self.webView.loadRequest(quest)
        
        self.sclView.delegate=self
        self.myView=UIView(frame:CGRect(x: self.sclView.center.x, y: self.sclView.center.y, width: 100, height: 100))
        self.myView?.contentMode = .scaleAspectFill
        self.sclView.addSubview(self.myView!)
        // Do any additional setup after loading the view, typically from a nib.
       
       
       
        // 設定擷取的畫面品質為相片品質（最高品質）
        // 其他的參數通常使用在錄影，例如VGA品質AVCaptureSessionPreset640x480
        // 如有需要請讀者自行參考 online help
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        // .builtInWideAngleCamera 為廣角鏡頭
        // .builtInTelephotoCamera 為長焦段鏡頭
        // .builtInDuoCamera 為雙鏡頭
        if #available(iOS 10.0, *) {
            if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                                          mediaType: AVMediaTypeVideo,
                                                          position: .back) {
                
                backCameraDevice = try! AVCaptureDeviceInput(device: device)
                
                // 將後置鏡頭加到session的輸入端
                session.addInput(backCameraDevice)
                // 將圖片輸出加到session的輸出端
                session.addOutput(AVCapturePhotoOutput())
                
                // 運用layer的方式將鏡頭目前“看到”的影像即時顯示到view元件上
                captureVideoPreviewLayer.session = session
                captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                myView?.layer.addSublayer(captureVideoPreviewLayer)
                
            }
        } else {
            // Fallback on earlier versions
        }
        
        // 前置鏡頭，類型為廣角鏡頭
        if #available(iOS 10.0, *) {
            if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                                          mediaType: AVMediaTypeVideo,
                                                          position: .front) {
                
                frontCameraDevice = try! AVCaptureDeviceInput(device: device)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureVideoPreviewLayer.frame = (myView?.bounds)!
    }


    
    @IBAction func takeClick(_ sender: Any) {
        if #available(iOS 10.0, *) {
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: imageView.frame.size.width,
                kCVPixelBufferHeightKey as String: imageView.frame.size.height,
                ] as [String : Any]
            
            settings.previewPhotoFormat = previewFormat
            
            if let output = session.outputs.first as? AVCapturePhotoOutput {
                output.capturePhoto(with: settings, delegate: self)
                
            } else {
                // Fallback on earlier versions
            }
        
        }
    }
    
    @available(iOS 10.0, *)
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        
        
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: photoSampleBuffer!,
            previewPhotoSampleBuffer: previewPhotoSampleBuffer
        )
        
        // 將圖片顯示在預覽的UIImage元件上
        self.imageView.image = UIImage(data: imageData!)
        
        // 圖片存檔
        UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
    }
   
    @IBAction func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed:
            // scale > 1 是放大
            // scale < 1 是縮小
            
            var newWidth=(self.myView?.bounds.width)! * sender.scale / 3
            if(newWidth<60){
                newWidth=60
            }
            if(newWidth>self.view.bounds.width){
                newWidth=self.view.bounds.width
            }
            var newHeight=(self.myView?.bounds.height)! * sender.scale / 3
            if(newHeight<60){
                newHeight=60
            }
            if(newHeight>self.view.bounds.width){
                newHeight=self.view.bounds.width
            }
//            self.myView.bounds = CGRect(x: 0, y: 0,
//                                        width: newWidth, height: newHeight)
            
//            let originCenter = self.myView.center
//            UIView.animate(
//                withDuration: 0.5,
//                animations: {
//                    self.myView.bounds = CGRect(
//                        x: 0, y: 0,
//                        width: newWidth, height: newHeight)
//                    
//            })
//            captureVideoPreviewLayer.frame = myView.bounds
            print("\(sender.scale)")
            
        default:
            break
        }
    }
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        // 修改前先呼叫 beginConfiguration
        session.beginConfiguration()
        
        // 將現有的 input 刪除
        session.removeInput(session.inputs[0] as! AVCaptureInput)

        
        if sender.isOn {
            // 後置鏡頭
            session.addInput(backCameraDevice)
        } else {
            // 前置鏡頭
            session.addInput(frontCameraDevice)
        }
        
        // 確認以上的所有修改
        session.commitConfiguration()
    }
    
     
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return self.imgView
//    }
  

    func cameraSetting() {
        guard let input = session.inputs.first as? AVCaptureDeviceInput else {
            print("session沒有輸入端")
            return
        }
        
        let camera = input.device!

        // 修改相機屬性前要先lock
        try! camera.lockForConfiguration()
        
        // 設定測光位置位於螢幕中央
        // 左上角為 (0, 0)，右下角為 (1, 1)
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
            camera.exposureMode = .continuousAutoExposure
        }
        
        // 設定螢幕中央對焦點，並採連續對焦模式
        // 左上角為 (0, 0)，右下角為 (1, 1)
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            camera.focusMode = .continuousAutoFocus
        }
        
        // 設定對焦距離: 0.0 為最短距離，1.0 為無限遠（預設值）
        // 此設定與 .ContinuousAutoFocus 效果互斥
        // camera.setFocusModeLockedWithLensPosition(0, completionHandler: nil)
        
        // 設定快門1/30秒與ISO 200
        camera.setExposureModeCustomWithDuration(
            CMTime(value: 1, timescale: 30),
            iso: 200,
            completionHandler: nil
        )
        
        // 修改完 unlock
        camera.unlockForConfiguration()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.myView
    }
    
    @IBAction func longTap(_ sender: UILongPressGestureRecognizer) {
        self.myView?.center=self.view.center
    }
    @IBAction func grap(_ sender: UIPanGestureRecognizer) {
        let gesturePoint = sender.location(in: self.sclView)
        switch sender.state {
      
        case .changed:
            // change the attachment's anchor point
            if let hitView = view.hitTest(gesturePoint,with:nil), hitView.superview == self.sclView {
                hitView.center = gesturePoint
            }
        default:
            break
        }

    }
    
}


