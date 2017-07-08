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
import Social

import Crashlytics

class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate,UISearchBarDelegate,
    CLLocationManagerDelegate
{
    var m_setList = [(title: String, isOn: Bool)]()
    
    var m_locationMamager:CLLocationManager!
    
    var m_location:CLLocation?
    
    let m_database = CKContainer.default().publicCloudDatabase
    
    let m_store = NSUbiquitousKeyValueStore()
    
    let m_UserDefault = UserDefaults.standard
    
    var m_alpha: Double = 0.8{
        didSet{
            let alpha = CGFloat(self.m_alpha)
            self.m_cameraView?.alpha = alpha
            self.imageView.alpha = alpha
            self.chang.alpha = alpha
            self.segCtl.alpha = alpha
            self.recBtn.alpha = alpha
        }
    }
    // 負責協調從截取裝置到輸出間的資料流動
    var m_session = AVCaptureSession()
    // 負責即時預覽目前相機設備截取到的畫面
    let m_captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    // 前置鏡頭
    var m_frontCameraDevice: AVCaptureDeviceInput?
    // 後置鏡頭
    var m_backCameraDevice: AVCaptureDeviceInput?

    @IBOutlet weak var chang: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var recBtn: UIButton!
    @IBOutlet weak var segCtl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    
    var m_backCamOn = true
    var m_cameraView: UIView?
    let m_imgVideo = UIImage(named: "video")
    let m_imgStop = UIImage(named: "stop")
    let m_imgPhoto = UIImage(named: "photo")
    
    let m_lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
    
    override func viewWillAppear(_ animated: Bool) {
        // tableView
        view.addSubview(self.tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        self.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        let c = self.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 256)
        c.identifier = "bottom"
        c.isActive = true
        
        self.tableView.layer.cornerRadius = 20
        
        super.viewWillAppear(animated)
    }
    
    fileprivate func initSetList(){
        self.m_setList.removeAll()
        self.m_setList.append((title: "Sound", isOn: true))
        self.m_setList.append((title: "Video", isOn: true))
        self.m_setList.append((title: "Delegate", isOn: true))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.m_session.stopRunning()
        
        // GPS
        self.m_locationMamager.stopUpdatingLocation()
    }
    @IBAction func slideChang(_ sender: UISlider) {
        self.m_alpha = Double(sender.value)
    }
    
    @IBAction func modeChang(_ sender: UISegmentedControl) {
        if(0==sender.selectedSegmentIndex){
//            self.recBtn.setTitle("TAKE", for: .normal)
            self.recBtn.setImage(self.m_imgPhoto, for: .normal)
        } else{
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
            do{
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if(self.m_session.canAddInput(audioInput)){
                    self.m_session.addInput(audioInput)
                }
            } catch{
                print(error)
            }
//            self.recBtn.setTitle("REC", for: .normal)
            self.recBtn.setImage(self.m_imgVideo, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initSetList()
        
        self.m_alpha = 0.9
        self.searchBar.delegate=self
//        if let strUrl = self.m_store.string(forKey: "URL"){
        if let strUrl = self.m_UserDefault.object(forKey: "URL") as? String{
            self.searchBar.text = strUrl
        } else{
            self.searchBar.text = "https://www.facebook.com"
        }
        
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
        if let input = self.m_backCameraDevice{
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
        
        // TODO: Track the user action that is important for you.
        Answers.logContentView(withName: "Tweet", contentType: "Video", contentId: "1234", customAttributes: ["Favorites Count":20, "Screen Orientation":"Landscape"])

        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
       
        if let url = URL(string:self.searchBar.text!){
            let quest = URLRequest(url: url)
            self.webView.loadRequest(quest)
            
//            self.m_store.set(self.searchBar.text, forKey: "URL")
//            if(!self.m_store.synchronize()){
            self.m_UserDefault.set(self.searchBar.text, forKey: "URL")
            if(!self.m_UserDefault.synchronize()){
                print("URL儲存失敗!")
            }
        }
        searchBar.resignFirstResponder()
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if(self.m_cameraView == nil){
            let screemSize = UIScreen.main.bounds.size
            self.m_cameraView=UIView(frame:CGRect(x: self.webView.center.x, y: self.webView.center.y, width: screemSize.width/2, height: screemSize.height/2))
            self.m_cameraView?.contentMode = .scaleAspectFill
            self.webView.addSubview(self.m_cameraView!)
        }
        
        self.m_captureVideoPreviewLayer.frame = (self.m_cameraView?.bounds)!
        
        self.m_session.startRunning()
        
        //運用layer的方式將鏡頭目前“看到”的影像即時顯示到view元件上
        self.m_captureVideoPreviewLayer.session = self.m_session
        self.m_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.m_cameraView?.layer.addSublayer(self.m_captureVideoPreviewLayer)
        self.m_cameraView?.center = self.webView.center
        
        self.m_lbl.textColor = UIColor.red
        self.m_cameraView?.addSubview(self.m_lbl)
        
//        self.slider.setValue(0.6, animated: false)
//        self.m_alpha = 0.6
        // GPS
        self.m_locationMamager.startUpdatingLocation()
        
        imageView.image = nil

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
                } else{
                    let fm = FileManager.default
                    
                    // 設定錄影的暫存檔路徑，我們把它放到 tmp 目錄下
                    let url = URL(fileURLWithPath: NSTemporaryDirectory() + "output.mov")
                    
                    // 判斷暫存檔是否已經存在，如果存在就刪掉它
                    if fm.fileExists(atPath: url.path) {
                        try! fm.removeItem(at: url)
                    }
                    
                    // 開始錄影
                    avCapOpt.startRecording(toOutputFileURL: url,recordingDelegate: self)
                    
//                    self.recBtn.setTitle("STOP", for: .normal)
                    self.recBtn.setImage(self.m_imgStop, for: .normal)
                    self.m_lbl.text = "◉REC"

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
        // 設定暫存檔路徑，我們把它放到 tmp 目錄下
        let path = NSTemporaryDirectory() + "output.jpg"
        let url = URL(fileURLWithPath: path)
        
        // 判斷暫存檔是否已經存在，如果存在就刪掉它
        if fm.fileExists(atPath: url.path) {
            try! fm.removeItem(at: url)
        }
        fm.createFile(atPath: path, contents: imageData, attributes: nil)
        
        alertAction(url: url,type: 0)
        
    }
    
    
    fileprivate func alertAction(url: URL?,type: Int){
        let alert = UIAlertController(title: "Share Message", message:
            "Give feedback", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        let loginAction = UIAlertAction(title: "Upload", style: .default)
        { (action) in
            let comment = alert.textFields?[0].text ?? ""
            self.retCKRecord(location:self.m_location,url: url,remark: comment,type: type)
            if(0==type){
                self.retSocialRec(comment:comment,url:url)
            }
        }
        
        // 產生一個文字輸入框
        alert.addTextField { (textField) in
            // 在要輸入帳號的text field中顯示淡淡的字串
            textField.placeholder = "Comment"
        }
        
        
        alert.addAction(cancelAction)
        alert.addAction(loginAction)
        show(alert, sender: self)
    }
    
    fileprivate func retSocialRec(comment:String?,url:URL?){
        
        // 先測試行動裝置內的服務設定是否完成
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
            
            let social = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            // 預先設定要PO的文字
            social?.setInitialText(comment)
            
            // PO文中加一個網址
//            social?.add(URL(string: "http://www.apple.com"))
            
            // PO文加一張圖片
            if let path = url?.path{
                social?.add(UIImage(contentsOfFile: path))
            }
            show(social!, sender: self)
        } else {
            print("系統不具備此服務或是尚未輸入帳號密碼")
        }
    }
    
    fileprivate func retCKRecord(location:CLLocation?,url: URL?,remark:String,type: Int){
        
        let record = CKRecord(recordType:"MyMedia")
        record["time"] = Date() as CKRecordValue?
        record["type"] = type as CKRecordValue
        record["remark"] = remark as CKRecordValue
        
        
        guard location != nil else{
            return
        }
        record["location"] = location

        if let _url = url{
            let asset = CKAsset(fileURL: _url)
            record["media"] = asset
            do{
                let data = try Data(contentsOf: _url)
                record["size"] = data.count as CKRecordValue
                
                let fm = FileManager.default
                // 設定錄影的暫存檔路徑，我們把它放到 tmp 目錄下
                
                let path = NSTemporaryDirectory() + record.recordID.recordName + (type == 0 ? ".jpg":".mov")
                let local = URL(fileURLWithPath: path)
                
                // 判斷暫存檔是否已經存在，如果存在就刪掉它
                if fm.fileExists(atPath: path) {
                    try! fm.removeItem(at: local)
                }
                fm.createFile(atPath: path, contents: data, attributes: nil)

            } catch {
                print(error)
            }
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
   
    @IBAction func switchClick(_ sender: UIButton) {
        
        self.m_backCamOn = !self.m_backCamOn
        // 修改前先呼叫 beginConfiguration
        self.m_session.beginConfiguration()
        
        // 將現有的 input 刪除
        for input in self.m_session.inputs{
            if (input is AVCaptureInput){
                self.m_session.removeInput(input as! AVCaptureInput)
            }
        }
        
        if self.m_backCamOn {
            // 後置鏡頭
            self.m_session.addInput(self.m_backCameraDevice)
        } else {
            // 前置鏡頭
            self.m_session.addInput(self.m_frontCameraDevice)
        }
        
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do{
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if(self.m_session.canAddInput(audioInput)){
                self.m_session.addInput(audioInput)
            }
        }catch {
            print(error)
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
//            if let hitView = view.hitTest(gesturePoint,with:nil), hitView == self.myView {
//                if(self.webView.bounds.contains(gesturePoint)){
//                    hitView.center =
//                        CGPoint(x:gesturePoint.x,y:gesturePoint.y-20)
//                }
//            }
            if(self.webView.bounds.contains(gesturePoint)){
                self.m_cameraView?.center =
                    CGPoint(x:gesturePoint.x,y:gesturePoint.y-20)
            }

        default:
            break
        }

    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        // 停止錄影後，這個method會被呼叫
        if error == nil {
            self.m_lbl.text = ""
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path) {
                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
                alertAction(url: outputFileURL,type: 1)
            }
        }else{
            print(error)
        }
//        self.recBtn.setTitle("REC", for: .normal)
        self.recBtn.setImage(self.m_imgVideo, for: .normal)
    }
    
    @IBAction func setting(_ sender: UIButton) {
        displayPickerView(true)
    }
    @IBAction func done(_ sender: UIButton) {
        displayPickerView(false)
    }
    func displayPickerView(_ show: Bool){
        for c in view.constraints{
            if c.identifier == "bottom"{
                c.constant = show ? -10 : 256
                break
            }
        }
        UIView.animate(withDuration: 0.5){
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        if( sender.state == .ended || sender.state == .changed) {
            
            let newScale = sender.scale
            self.m_cameraView?.transform = CGAffineTransform(scaleX: newScale, y: newScale)
            
        }
    }
}

extension CameraVC : UITableViewDataSource, UITableViewDelegate
{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.m_setList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setCell", for: indexPath) as! SettingCell
        cell.m_label?.text = self.m_setList[indexPath.row].title
        cell.m_switch?.isOn = self.m_setList[indexPath.row].isOn
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
}


