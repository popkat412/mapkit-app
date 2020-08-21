//
//  ViewController.swift
//  Mapkit App
//
//  Created by Wang Yunze on 5/8/20.
//  Copyright © 2020 yunze. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    
    
    @IBOutlet weak var saveLocationButton: UIButton!
    
    var pastLocations = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        
        mapView.showsUserLocation = true
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check for Location Services
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    
    @IBAction func saveLocationPressed(_ sender: Any) {
        print("Saving location... \(currentLocation ?? CLLocation())")
        if let unwrappedLocation = currentLocation {
            save(location: unwrappedLocation)
        }
        
        // Dont allow spamming of save location button
        saveLocationButton.isEnabled = false
        saveLocationButton.backgroundColor = UIColor.systemGray2
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.saveLocationButton.isEnabled = true
            self.saveLocationButton.backgroundColor = UIColor.link

        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPastLocations" {
            if let dest = segue.destination as? PastLocationsTableViewController {
                dest.pastLocations = getPreviousLocations() ?? [NSManagedObject]()
            }
        }
    }
    
    
    private func getPreviousLocations() -> [NSManagedObject]? {
        print("Getting previous locations...")
        
        //1
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        
        let managedContext =
          appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
          NSFetchRequest<NSManagedObject>(entityName: "Location")
        
        //3
        do {
            return try managedContext.fetch(fetchRequest).reversed()
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return nil
    }
    
    private func handleError(_ error: Error) {
        let alert = UIAlertController(title: "Error while reverse gecoding location", message: "\(error.localizedDescription)", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))

        self.present(alert, animated: true)

    }

    
    private func save(location locToSave: CLLocation) {
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
          return
        }
        
        let managedContext =
          appDelegate.persistentContainer.viewContext
        
        let entity =
          NSEntityDescription.entity(forEntityName: "Location",
                                     in: managedContext)!
        
        let location = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(locToSave) { (placemarks, error) in
            guard error == nil else {
                self.handleError(error!)
                return
            }
            
            if let firstPlacemark = placemarks?.first {
                let locationName = "\(firstPlacemark.locality!), \(firstPlacemark.name!)"
                
                print("Reverse geocoding result: \(locationName)")
                
                location.setValue(locToSave.coordinate.longitude, forKey: "longitude")
                location.setValue(locToSave.coordinate.latitude, forKey: "latitude")
                location.setValue(locToSave.timestamp, forKey: "timestamp")
                location.setValue(locationName, forKey: "locationName")
                
                do {
                    try managedContext.save()
                    self.pastLocations.append(location)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
        // Zoom to user location
        if let userLocation = locations.last {
            let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(viewRegion, animated: true)
        }
    }
}

