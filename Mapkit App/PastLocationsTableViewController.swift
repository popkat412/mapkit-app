//
//  PastLocationsTableViewController.swift
//  Mapkit App
//
//  Created by Wang Yunze on 5/8/20.
//  Copyright © 2020 yunze. All rights reserved.
//

import UIKit
import CoreData

class PastLocationsTableViewController: UITableViewController {
    
    var pastLocations: [NSManagedObject]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pastLocations.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pastLocCell", for: indexPath)

        let currentLoc = pastLocations[indexPath.row]
        // Configure the cell...
        
        // let latitude = currentLoc.value(forKey: "latitude") as? Double ?? 0
        // let longitude = currentLoc.value(forKey: "longitude") as? Double ?? 0
        
        // print("latitude: \(latitude) longitude: \(longitude)")
        
        let locationName = currentLoc.value(forKey: "locationName") as? String ?? "🤷🏻‍♂️"
        cell.textLabel?.text = locationName

        let date = currentLoc.value(forKeyPath: "timestamp") as? Date ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a, MMM dd, yyyy"
        let displayDate = dateFormatter.string(from: date)
        
        cell.detailTextLabel?.text = displayDate

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showCoordOnMap" {
            if let dest = segue.destination as? ShowCoordOnMapViewController {
                let indexPath = tableView.indexPathForSelectedRow!
                let currentLoc = pastLocations[indexPath.row]
                dest.latitude = currentLoc.value(forKey: "latitude") as? Double ?? 0
                dest.longitude = currentLoc.value(forKey: "longitude") as? Double ?? 0
                dest.locationName = currentLoc.value(forKey: "locationName") as? String ?? ""
            }
        }
    }
    

}
