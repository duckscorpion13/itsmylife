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
    @IBOutlet weak var mapView: MKMapView!
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
        
        let lookupInfo = userIdentify?.lookupInfo
        let nameComponents = userIdentify?.nameComponents
        
        print("email: \(lookupInfo?.emailAddress)")
        print("phone: \(lookupInfo?.phoneNumber)")
        
        print("givenName: \(nameComponents?.givenName)")
        print("familyName: \(nameComponents?.familyName)")
    }
    
    fileprivate func fetchAll() {
//        let date = NSDate(timeInterval: -60.0 * 120, sinceDate: NSDate())
//        let predicate = NSPredicate(format: "creationDate > %@", date)
        let predicate = NSPredicate(format: "TRUEPREDICATE")
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
    fileprivate var cloudKitObserver: NSObjectProtocol?
    
    fileprivate func iCloudSubscribe() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKQuerySubscription(
            recordType: "MyMedia",
            predicate: predicate,
            subscriptionID: self.subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion]
        )
        // subscription.notificationInfo = ...
        self.m_database.save(subscription, completionHandler: { (savedSubscription, error) in
            if error?._code == CKError.serverRejectedRequest.rawValue {
                // ignore
            } else if error != nil {
                // report
            }
        })
        cloudKitObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "iCloudRemoteNotificationReceived"),
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                if let ckqn = notification.userInfo?["Notification"] as? CKQueryNotification {
                    self.iCloudHandleSubscriptionNotification(ckqn)
                }
            }
        )
    }
    
    fileprivate func iCloudHandleSubscriptionNotification(_ ckqn: CKQueryNotification)
    {
        if ckqn.subscriptionID == self.subscriptionID {
            if let recordID = ckqn.recordID {
                switch ckqn.queryNotificationReason {
                case .recordCreated:
                    self.m_database.fetch(withRecordID: recordID) { (record, error) in
                        if record != nil {
                            DispatchQueue.main.async {
                                self.m_allMedia = (self.m_allMedia + [record!]).sorted {
                                    return $0.creationDate! < $1.creationDate!
                                }
                            }
                        }
                    }
                    
                case .recordDeleted:
                    DispatchQueue.main.async {
                        self.m_allMedia = self.m_allMedia.filter { $0.recordID != recordID }
                    }
                default:
                    break
                }
            }
        }
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
            if (annotation.title)! == anno.title {
                // 設定左邊為一張圖片
                if let media = anno.media{
                    let image = UIImage(contentsOfFile: media.fileURL.path)
                    let imageView = UIImageView(frame: CGRect(x:0,y:0,width:50,height:50))
                    imageView.image=image
                    annView?.leftCalloutAccessoryView = imageView
                }
                // 設定title下方放一個標籤
                let label = UILabel()
                label.numberOfLines = 2
                label.text = "緯度:\(annotation.coordinate.latitude)\n經度:\(annotation.coordinate.longitude)"
                annView?.detailCalloutAccessoryView = label
                
                // 設定右邊為一個按鈕
                let button = UIButton(type: .detailDisclosure)
//                button.tag =
                button.addTarget(self, action: #selector(self.btnPress), for: .touchUpInside)
            
                annView?.rightCalloutAccessoryView = button
                break
            }
        }
        annView?.canShowCallout = true
        
        return annView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let media = (view.annotation as? MyAnnotation)?.media{
            self.m_image = UIImage(contentsOfFile: media.fileURL.path)
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
    
 

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
