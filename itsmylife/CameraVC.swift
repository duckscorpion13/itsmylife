//
//  CameraVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/28.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import AssetsLibrary
import CloudKit
import MapKit



class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate,UISearchBarDelegate,
    CLLocationManagerDelegate{

    var m_locationMamager:CLLocationManager!
    
    var m_location:CLLocation?
    
    let m_database = CKContainer.default().publicCloudDatabase
    
    let m_store = NSUbiquitousKeyValueStore()
    
    let m_UserDefault = UserDefaults.standard
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
    @IBOutlet weak var imageView: UIImageView!
    
    var myView: UIView?
    
    override func viewWillDisappear(_ animated: Bool) {
        self.m_session.stopRunning()
        
        // GPS
        self.m_locationMamager.stopUpdatingLocation()
    }
    @IBAction func slideChang(_ sender: UISlider) {
        self.myView?.alpha=CGFloat(sender.value)
    }
    
    @IBAction func modeChang(_ sender: UISegmentedControl) {
        if(0==sender.selectedSegmentIndex){
            self.recBtn.setTitle("TAKE", for: .normal)
        }else{
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
            do{
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if(self.m_session.canAddInput(audioInput)){
                    self.m_session.addInput(audioInput)
                }
            }catch {
                print(error)
            }
            self.recBtn.setTitle("REC", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.delegate=self
        if let strUrl = self.m_UserDefault.object(forKey: "URL") as? String{
            self.searchBar.text = strUrl
        } else{
            self.searchBar.text = "https://www.apple.com.tw"
        }
        
//        if let strUrl = self.m_store.string(forKey: "URL"){
//            self.searchBar.text = strUrl
//        }
//        else{
//            self.searchBar.text = "https://www.apple.com.tw"
//        }
        
        if let url = URL(string:searchBar.text!){
            let quest = URLRequest(url: url)
            self.webView.loadRequest(quest)
        }
        self.webView.scrollView.zoomScale=1.0
        
      
        
        
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
        if let input=self.m_backCameraDevice{
            if(self.m_session.canAddInput(input)){
                self.m_session.addInput(input)
            }
        }
        
        if(self.m_session.canAddOutput(AVCapturePhotoOutput())){
            self.m_session.addOutput(AVCapturePhotoOutput())
        }
        
        // 設定 movie （包含 video 與 audio）為輸出對象
        let output = AVCaptureMovieFileOutput()
        // 錄製10秒鐘後自動停止，如果沒有設定maxRecordedDuration這個屬性的話，預設值為無限大
        output.maxRecordedDuration = CMTime(value: 3600, timescale: 1)
        if(self.m_session.canAddOutput(output)){
            self.m_session.addOutput(output)
        }
        
        // GPS
        self.m_locationMamager = CLLocationManager()
        self.m_locationMamager.delegate = self
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
       
        if let url = URL(string:self.searchBar.text!){
            let quest = URLRequest(url: url)
            self.webView.loadRequest(quest)
            
            self.m_UserDefault.set(self.searchBar.text, forKey: "URL")
            if(!self.m_UserDefault.synchronize()){
                print("URL儲存失敗!")
            }
            
//            self.m_store.set(self.searchBar.text, forKey: "URL")
//            if(!self.m_store.synchronize()){
//                print("URL儲存失敗!")
//            }
            
        }
        searchBar.resignFirstResponder()
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if(self.myView == nil){
            self.myView=UIView(frame:CGRect(x: self.webView.center.x, y: self.webView.center.y, width: 100, height: 100))
            self.myView?.contentMode = .scaleAspectFill
            self.webView.addSubview(self.myView!)
        }
        
        self.m_captureVideoPreviewLayer.frame = (self.myView?.bounds)!
        
        self.m_session.startRunning()
        
        //運用layer的方式將鏡頭目前“看到”的影像即時顯示到view元件上
        self.m_captureVideoPreviewLayer.session = self.m_session
        self.m_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.myView?.layer.addSublayer(self.m_captureVideoPreviewLayer)
        
        self.myView?.center=self.webView.center
        self.myView?.alpha=0.5
        
        // GPS
        self.m_locationMamager.startUpdatingLocation()

    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.m_location = locations[0]
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
                    avCapOpt.startRecording(toOutputFileURL: url,recordingDelegate: self)
                    
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
        
        let fm = FileManager.default
        // 設定錄影的暫存檔路徑，我們把它放到 tmp 目錄下
        let path = NSTemporaryDirectory() + "output.jpg"
        let url = URL(fileURLWithPath: path)
        
        // 判斷暫存檔是否已經存在，如果存在就刪掉它
        if fm.fileExists(atPath: url.path) {
            try! fm.removeItem(at: url)
        }
        fm.createFile(atPath: path, contents: imageData, attributes: nil)
        
        retCKRecord(location:self.m_location,url: url)
    }
    
    fileprivate func retCKRecord(location:CLLocation?,url: URL?){
        let record = CKRecord(recordType:"MyMedia")
        record["time"] = Date() as CKRecordValue?
        
        if let _location = location{
            record["location"] = _location
        }
        if let _url = url{
            let asset = CKAsset(fileURL: _url)
            record["media"] = asset
        }
        
        self.m_database.save(record, completionHandler:{ (record, error) in
            if error == nil {
                print("success")
            }
            else{
                print("falure")
            }
        })
    }
   
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        // 修改前先呼叫 beginConfiguration
        self.m_session.beginConfiguration()
        
        // 將現有的 input 刪除
        for input in self.m_session.inputs{
            if ((input as? AVCaptureInput) != nil){
                self.m_session.removeInput(input as! AVCaptureInput)
            }
        }
        
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
        let gesturePoint = sender.location(in: self.webView)
        switch sender.state {
      
        case .changed:
            // change the attachment's anchor point
            if let hitView = view.hitTest(gesturePoint,with:nil), hitView == self.myView {
                if(self.webView.bounds.contains(gesturePoint)){
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
    
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        if( sender.state == .ended || sender.state == .changed) {
            
            let newScale = sender.scale
            self.myView?.transform = CGAffineTransform(scaleX: newScale, y: newScale)
            
        }
    }
}


