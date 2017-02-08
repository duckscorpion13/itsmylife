
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
import AssetsLibrary

class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate{

    // 負責協調從截取裝置到輸出間的資料流動
    var m_session = AVCaptureSession()
    // 負責即時預覽目前相機設備截取到的畫面
    let m_captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    // 前置鏡頭
    var m_frontCameraDevice: AVCaptureDeviceInput?
    // 後置鏡頭
    var m_backCameraDevice: AVCaptureDeviceInput?

    @IBOutlet weak var recBtn: UIButton!
    @IBOutlet weak var segCtl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var sclView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var myView: UIView?
    
    override func viewWillDisappear(_ animated: Bool) {
        self.m_session.stopRunning()
    }
    @IBAction func slideChang(_ sender: UISlider) {
        self.myView?.alpha=CGFloat(sender.value)
    }
    
    @IBAction func modeChang(_ sender: UISegmentedControl) {
//        self.m_session.beginConfiguration()
//        self.m_session.removeOutput(self.m_session.outputs[0] as! AVCaptureOutput)
//        if(0==sender.selectedSegmentIndex){
//            self.m_session.addOutput(AVCapturePhotoOutput())
//        }
//        else{
//            videoSet(self.m_session)
//        }
//        self.m_session.commitConfiguration()
        if(0==sender.selectedSegmentIndex){
            self.recBtn.setTitle("TAKE", for: .normal)
        }else{
            self.recBtn.setTitle("REC", for: .normal)
        }
         
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sclView.delegate=self
        
        let url = URL(string:searchBar.text!)
        let quest = URLRequest(url: url!)
        self.webView.loadRequest(quest)
        
        
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do{
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            self.m_session.addInput(audioInput)
        }catch {
            print(error)
        }
        
        
        // .builtInWideAngleCamera 為廣角鏡頭
        // .builtInTelephotoCamera 為長焦段鏡頭
        // .builtInDuoCamera 為雙鏡頭
        // 後置鏡頭，類型為廣角鏡頭
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                                      mediaType: AVMediaTypeVideo,
                                                      position: .back) {
            self.m_backCameraDevice = try! AVCaptureDeviceInput(device: device)
        }
        
        // 前置鏡頭，類型為廣角鏡頭
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                                      mediaType: AVMediaTypeVideo,
                                                      position: .front) {
            
            self.m_frontCameraDevice = try! AVCaptureDeviceInput(device: device)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // 設定擷取的畫面品質為相片品質（最高品質）
        // 其他的參數通常使用在錄影，例如VGA品質AVCaptureSessionPreset640x480
        // 如有需要請讀者自行參考 online help
        self.m_session.sessionPreset = AVCaptureSessionPreset640x480//AVCaptureSessionPresetPhoto
        self.m_session.addInput(self.m_backCameraDevice!)
        
        self.m_session.addOutput(AVCapturePhotoOutput())
        
        // 設定 movie （包含 video 與 audio）為輸出對象
        let output = AVCaptureMovieFileOutput()
        // 錄製10秒鐘後自動停止，如果沒有設定maxRecordedDuration這個屬性的話，預設值為無限大
        output.maxRecordedDuration = CMTime(value: 3600, timescale: 1)
        self.m_session.addOutput(output)
    }
        
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.myView=UIView(frame:CGRect(x: self.sclView.center.x, y: self.sclView.center.y, width: 100, height: 100))
        self.myView?.contentMode = .scaleAspectFill
        self.sclView.addSubview(self.myView!)
        
        self.m_captureVideoPreviewLayer.frame = (self.myView?.bounds)!
        
        self.m_session.startRunning()
        
        //運用layer的方式將鏡頭目前“看到”的影像即時顯示到view元件上
        self.m_captureVideoPreviewLayer.session = self.m_session
        self.m_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.myView?.layer.addSublayer(self.m_captureVideoPreviewLayer)
        
        self.myView?.center=self.view.center
        self.myView?.alpha=0.5

    }


    
    @IBAction func takeClick(_ sender: Any) {
        if(0==self.segCtl.selectedSegmentIndex){
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: imageView.frame.size.width,
                kCVPixelBufferHeightKey as String: imageView.frame.size.height,
                ] as [String : Any]
            
            settings.previewPhotoFormat = previewFormat
            
            if let output = self.m_session.outputs.first as? AVCapturePhotoOutput {
                output.capturePhoto(with: settings, delegate: self)
            }
        }else{
            if let avCapOpt = (self.m_session.outputs[1] as? AVCaptureMovieFileOutput){
                if avCapOpt.isRecording{
                    avCapOpt.stopRecording()
                }else{
                    let fm = FileManager.default
                    
                    // 設定錄影的暫存檔路徑，我們把它放到 tmp 目錄下
                    let url = URL(fileURLWithPath: NSTemporaryDirectory() + "output.mov")
                    
                    // 判斷暫存檔是否已經存在，如果存在就刪掉它
                    if fm.fileExists(atPath: url.path) {
                        try! fm.removeItem(at: url)
                    }
                    
                    // 開始錄影
                    avCapOpt.startRecording(toOutputFileURL: url, recordingDelegate: self)
                     self.recBtn.setTitle("STOP", for: .normal)
                }
            }
        }
    }
    
    
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
   
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        // 修改前先呼叫 beginConfiguration
        self.m_session.beginConfiguration()
        
        // 將現有的 input 刪除
        self.m_session.removeInput(self.m_session.inputs[1] as! AVCaptureInput)

        
        if sender.isOn {
            // 後置鏡頭
            self.m_session.addInput(self.m_backCameraDevice)
        } else {
            // 前置鏡頭
            self.m_session.addInput(self.m_frontCameraDevice)
        }
        
        // 確認以上的所有修改
        self.m_session.commitConfiguration()
    }
    
    

    func cameraSetting() {
        guard let input = self.m_session.inputs.first as? AVCaptureDeviceInput else {
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
    
    
    
    @IBAction func grap(_ sender: UIPanGestureRecognizer) {
        let gesturePoint = sender.location(in: self.sclView)
        switch sender.state {
      
        case .changed:
            // change the attachment's anchor point
            if let hitView = view.hitTest(gesturePoint,with:nil), hitView == self.myView {
                if(self.sclView.bounds.contains(gesturePoint)){
                    hitView.center =
                        CGPoint(x:gesturePoint.x,y:gesturePoint.y-20)
                }
            }
        default:
            break
        }

    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        // 停止錄影後，這個method會被呼叫
        if error == nil {
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path) {
                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            }
        }else{
            print(error)
        }
        
        self.recBtn.setTitle("REC", for: .normal)
    }
    
}

extension CameraVC: UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.myView
    }
}

