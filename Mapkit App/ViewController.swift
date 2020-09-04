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
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UNUserNotificationCenterDelegate {
    // RI Coordinates: 1.3466753,103.8413648
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var saveLocationButton: UIButton!
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var previousStationaryLoc: CLLocation?
    var lastFewLocations = [CLLocation]()
    var pastLocations = [NSManagedObject]()
    
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        userNotificationCenter.delegate = self
        
        mapView.showsUserLocation = true
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        
        // Check for Location Services
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        requestNotificationAuthorization()
        
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
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPastLocations" {
            if let dest = segue.destination as? PastLocationsTableViewController {
                dest.pastLocations = getPreviousLocations() ?? [NSManagedObject]()
            }
        }
    }
    
    // MARK: Helper methods
    
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
    
    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }
    
    func sendNotification() {
        let notificationContent = UNMutableNotificationContent()
        
        // Add the content to the notification content
        notificationContent.title = "Remember to check in/out!"
        notificationContent.body = "You moved more than 10m from your previous spot, which is why you are receiving this message"
        
        let request = UNNotificationRequest(identifier: "testNotification",
                                            content: notificationContent, trigger: nil)
        
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
    
    // MARK: Delegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer {
            currentLocation = locations.last
            if let currentLocation = currentLocation {
                lastFewLocations.append(currentLocation)
            }
            
            
            if lastFewLocations.count > 10 {
                // Only keep track of past 10 locations
                lastFewLocations.remove(at: 0)
            }
        }
        
        if let userLocation = locations.last {
            // Zoom to user location
            let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
            mapView.setRegion(viewRegion, animated: true)
            
            // Check if user moved more than 10meters
            if let previousStationaryLoc = previousStationaryLoc {
                if userLocation.distance(from: previousStationaryLoc) > 10 {
                    print("Moved 10m from previous location")
                    sendNotification()
                }
            }
            
            // Update `previousStationaryLoc`
            var totalDistMoved = 0.0
            if lastFewLocations.count > 1{
                for i in 0..<lastFewLocations.count-1 {
                    totalDistMoved += lastFewLocations[i].distance(from: lastFewLocations[i+1])
                }
            }
            
            if totalDistMoved < 5 {
                previousStationaryLoc = userLocation
                print("Was stationary...")
            }
            
            print("previousStationaryLoc: \(previousStationaryLoc), lastFewLocations: \(lastFewLocations)")
            
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
}

