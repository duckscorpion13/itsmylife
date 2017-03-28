//
//  MapVC.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/28.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import MapKit
import CloudKit

class MyAnnotation:NSObject,MKAnnotation{
    
    init(rec:CKRecord) {
        self.m_rec = rec
    }
    
    let m_rec:CKRecord
    
    var coordinate: CLLocationCoordinate2D {
        let loc = self.m_rec["location"] as? CLLocation
        return CLLocationCoordinate2D(latitude: loc!.coordinate.latitude, longitude: loc!.coordinate.longitude)
    }
    
    var title: String? {
        if let date = self.m_rec["time"] as? NSDate{
            return "\(date)"
        }
        return ""
    }
    
    var subtitle: String? { return "" }
    
    var media:CKAsset?{
        if let asset = self.m_rec["media"] as? CKAsset{
            return asset
        }
        return nil
    }
    
    var imgView: UIImageView?
}


class MapVC: UIViewController,MKMapViewDelegate  {

    var m_allMedia = [CKRecord]() {
        didSet{
            self.mapView.removeAnnotations(self.m_allAnnos)
            self.m_allAnnos.removeAll()
            for rec in self.m_allMedia{
                let ann = MyAnnotation(rec: rec)
                self.m_allAnnos.append(ann)
            }
            self.mapView.addAnnotations(self.m_allAnnos)
        }
    }
    let m_database = CKContainer.default().publicCloudDatabase
    var m_allAnnos = [MyAnnotation]()
    var m_image:UIImage?
    var m_urlMap = [String:URL]()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate=self
        
        // 使用預設的 container
        let container = CKContainer.default()
        
        // 要求使用者授權登入 iCloud
        container.requestApplicationPermission(.userDiscoverability)
        { (status, error) in
            
            switch status {
            case .initialState:
                print("使用者尚未決定是否要授權")
                
            case .granted:
                print("使用者已經授權")
                
                container.fetchUserRecordID(completionHandler: { (recordID, error) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    guard recordID != nil else {
                        return
                    }
                    
                    container.discoverUserIdentity(withUserRecordID: recordID!, completionHandler: { (userIdentity, error) in
                        // 這個區段的程式已經不在主執行緒
                        self.getUserInfo(userIdentify: userIdentity, error: error)
                    })
                })
                
            case .denied:
                print("使用者拒絕授權")
                
            case .couldNotComplete:
                print(error!)
            }
        }

    }
    override func viewWillAppear(_ animated: Bool) {
        fetchAll()
        iCloudSubscribe()
    }
    
    func getUserInfo(userIdentify: CKUserIdentity?, error: Error?) {
        guard error == nil else {
            print(error!)
            return
        }
        
        guard userIdentify != nil else {
            return
        }
        
        if let lookupInfo = userIdentify?.lookupInfo{
            print("email: \(String(describing: lookupInfo.emailAddress))")
            print("phone: \(String(describing: lookupInfo.phoneNumber))")
        }
        if let nameComponents = userIdentify?.nameComponents{
            let giveName = nameComponents.givenName ?? ""
            let familyName = nameComponents.familyName ?? ""
            self.userBtn.setTitle(giveName + " " + familyName, for: .normal)
    
            print("givenName: \(giveName)")
            print("familyName: \(familyName)")
        }
    }
    
    func fetchAll() {
        let date = NSDate(timeInterval: -86400, since: Date())
        let predicate = NSPredicate(format: "time > %@", date)
//        let predicate = NSPredicate(value:true)
        let query = CKQuery(recordType: "MyMedia", predicate: predicate)
//        query.sortDescriptors = [NSSortDescriptor(key: Cloud.Attribute.Question, ascending: true)]
        self.m_database.perform(query, inZoneWith: nil) { (records, error) in
            if records != nil {
                DispatchQueue.main.async {
                    self.m_allMedia = records!
                }
            }
        }
    }
    
    // MARK: Subscription
    
    fileprivate let subscriptionID = "All Media Creations and Deletions"
  
    fileprivate func iCloudSubscribe() {
        let predicate = NSPredicate(value:true)
        let subscription = CKQuerySubscription(
            recordType: "MyMedia",
            predicate: predicate,
            subscriptionID: self.subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )
        let note = CKNotificationInfo()
        note.alertBody = "update data"
        subscription.notificationInfo = note
        // subscription.notificationInfo = ...
        self.m_database.save(subscription, completionHandler: { (savedSubscription, error) in
            if error == nil {
                print("subscriip success")
            }
            else{
                print("subscriip falure:\(String(describing: error))")
            }
        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
        if (annView == nil) {
            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier:
                "Pin")
        }
        for anno in self.m_allAnnos{
            let name = anno.m_rec.recordID.recordName
            if (annotation.title)! == anno.title {
                // 設定左邊為一張圖片
                if let media = anno.media{
                    let imageView = UIImageView(frame: CGRect(x:0,y:0,width:50,height:50))
                    anno.imgView = imageView
                    if((self.m_urlMap[name]) == nil){
                        
                        // 使用預設的設定建立 session
                        let config = URLSessionConfiguration.default
                        let session = URLSession(configuration: config)
                        // NSURLSessionDataTask 為讀取資料，讀取完成的資料會放在 data 中
                        let dataTask = session.dataTask(with: media.fileURL) { (data, response, error) in
                            // 注意此 block 區段已在另外一個執行緒
                            if error == nil {
                                if let data = data {
                                    let fm = FileManager.default
                                    // 設定錄影的暫存檔路徑，我們把它放到 tmp 目錄下
                                    let path = NSTemporaryDirectory() + name
                                    let url = URL(fileURLWithPath: path)
                                    
                                    // 判斷暫存檔是否已經存在，如果存在就刪掉它
                                    if fm.fileExists(atPath: path) {
                                        try! fm.removeItem(at: url)
                                    }
                                    fm.createFile(atPath: path, contents: data, attributes: nil)
                                    self.m_urlMap[name] = url
                                }
                            } else {
                                print("資料讀取失敗")
                            }
                        }
                        // 開始讀取資料
                        dataTask.resume()
                    }
//                    imageView.image=self.m_imageMap[anno.m_rec.recordID.recordName]
                    annView?.leftCalloutAccessoryView = imageView
                }
                
                
                // 設定title下方放一個標籤
                let label = UILabel()
                label.numberOfLines = 2
                let lati = String(format:"%.5f",annotation.coordinate.latitude)
                let longi = String(format:"%.5f",annotation.coordinate.longitude)

                label.text = "緯度:\(lati)\n經度:\(longi)"
                annView?.detailCalloutAccessoryView = label
                
                // 設定右邊為一個按鈕
                let button = UIButton(type: .detailDisclosure)
               
                button.addTarget(self, action: #selector(self.btnPress), for: .touchUpInside)
            
                annView?.rightCalloutAccessoryView = button
                break
            }
        }
        annView?.canShowCallout = true
        
        return annView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let anno = view.annotation as? MyAnnotation{
            let name =  anno.m_rec.recordID.recordName
            if let path = self.m_urlMap[name]?.path{
                if let image = UIImage(contentsOfFile: path){
                    anno.imgView?.image = image
                    self.m_image = image
                }
            }
        }
        
    }
    
    func btnPress(_ sender:UIButton){
        if let vc=self.storyboard?.instantiateViewController(withIdentifier: "SVC") as? ScrollVC{
            vc.m_img=self.m_image
            self.show(vc, sender: self)
        }
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            return nil
//        }
//        
//        var annView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
//        if annView == nil {
//            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
//        }
//        
//        // 允許使用者可以拖放大頭針
//        annView?.isDraggable = true
//        
//        return annView
//    }

//    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
//        if newState == .ending {
//            view.dragState = .none
//        }
//    }


}
