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



class MapVC: UIViewController,MKMapViewDelegate  {

    var m_allMedia = [CKRecord]() { didSet{
        self.mapView.removeAnnotations(self.m_allAnnos)
        self.m_allAnnos.removeAll()
            for rec in self.m_allMedia{
                let ann = MKPointAnnotation()
                if let loc=rec["location"] as? CLLocation{
                    ann.coordinate.latitude=loc.coordinate.latitude
                    ann.coordinate.longitude=loc.coordinate.longitude
                }
                self.m_allAnnos.append(ann)
                self.mapView.addAnnotation(ann)
            }
        }
    }
    let m_database = CKContainer.default().publicCloudDatabase
    var m_allAnnos = [MKAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate=self
//        let ann = MKPointAnnotation()
//        ann.coordinate=CLLocationCoordinate2DMake(24.402551, 121.161865)
//        mapView.addAnnotation(ann)
    }
    override func viewWillAppear(_ animated: Bool) {
        fetchAll()
        iCloudSubscribe()
    }
    fileprivate func fetchAll() {
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
        if annView == nil {
            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        }
        
        // 允許使用者可以拖放大頭針
        annView?.isDraggable = true
        
        return annView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .ending {
            view.dragState = .none
        }
    }
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        mapView.removeAnnotation(view.annotation!)
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
