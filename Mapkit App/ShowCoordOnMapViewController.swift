//
//  ShowCoordLocViewController.swift
//  Mapkit App
//
//  Created by Wang Yunze on 5/8/20.
//  Copyright © 2020 yunze. All rights reserved.
//

import UIKit
import MapKit

class ShowCoordOnMapViewController: UIViewController {
    var longitude: Double!
    var latitude: Double!
    var locationName: String!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        titleLabel.text = "\(locationName!)\n\(latitude!), \(longitude!)"
        
        let coord = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let viewRegion = MKCoordinateRegion(center: coord, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(viewRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        mapView.addAnnotation(annotation)
        
    }
    

    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
