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

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate=self
//        let ann = MKPointAnnotation()
//        ann.coordinate=CLLocationCoordinate2DMake(24.402551, 121.161865)
//        mapView.addAnnotation(ann)
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
