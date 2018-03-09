//
//  DataLoader.swift
//  iOSEventApp
//
//  Created by Nathaniel Brown on 3/5/18.
//  Copyright © 2018 LightSys. All rights reserved.
//

import Foundation
import CoreData

class DataController: NSObject {
//  var managedObjectContext: NSManagedObjectContext
  var persistentContainer: NSPersistentContainer
  let sidebarNameKey = "nav"
  let sidebarIconKey = "icon"
  let sidebarAppearanceEntityName = "SidebarAppearance"
  let orderKey = "order"
  
  init(newPersistentContainer: NSPersistentContainer) {
    persistentContainer = newPersistentContainer
//    persistentContainer = NSPersistentContainer(name: "DataModel")
//    persistentContainer.loadPersistentStores() { (description, error) in
//      if let error = error {
//        fatalError("Failed to load Core Data stack: \(error)")
//      }
//      completionClosure()
//    }
  }

  // TODO: Change the deletion of old data to happen just once, after data is loaded.
  func loadDataFromURL(_ url: URL) {
    
    deleteAll(forEntityName: "SidebarAppearance")
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      guard error == nil else {
        print("Error: \(error!)")
        return
      }
      guard let unwrappedData = data else {
        print("There was no data")
        return
      }
      
      do {
        let jsonDict = try JSONSerialization.jsonObject(with: unwrappedData) as! [String: Any]
        let prayerPartners = jsonDict["prayer_partners"] as! [[String: Any]]
        self.generatePrayerPartnerModel(from: prayerPartners)
//        print(prayerPartners)
        // index 0. general info? = key:"nav" value:"Prayer Partners"
        //                          key:"icon" value:"ic_group"
        
        // index 1-8 Partners = key:"students" value:"First Last\nFirst Last..."
        
        let housing = jsonDict["housing"] as! [String: Any]
        self.generateHousingModel(from: housing)
        // General info
        // key:"nav" value "Housing"
        // key "icon" value:"ic_house"
        
        // Hosts:
        // key: (hostname) value ["students": "(students)", "driver": "(driver)"]
        
        let general = jsonDict["general"] as! [String: Any]
        self.generateGeneralModel(from: general)
        // Keys: "time_zone" "notifications_url" "welcome_message" "year" "refresh" "refresh_expire" "logo"
        
        let contactPage = jsonDict["contact_page"] as! [String: Any]
        self.generateContactPageModel(from: contactPage)
/*    - key : "icon"
 - value : ic_contact
*/
        // key: "section_1"
        // value ["content":(string), "id":0, "header":(string)]
        // key: "section_2"
        // value ["content":(string), "id":1, "header":(string)]
        // key: "nav"
        // value "Contacts"
        
        let contacts = jsonDict["contacts"] as! [String: Any]
        self.generateContactModel(from: contacts)
        // key: "name"
        // value: ["address":(address), "phone":(phone?)]
        // NO NAV?
        
        let theme = jsonDict["theme"] as! [[String: Any]]
        // array of ["key":"#XXXXXX"]
        
        
        // DATA MODEL PAUSE
        
        let informationPage = jsonDict["information_page"] as! [String: Any]
        self.generateInformationPageModel(from: informationPage)
//        // "page_1": (something), "page_2": (something)
//
        let schedule = jsonDict["schedule"] as! [String: Any]
        self.generateSchedulePageModel(from: schedule)
        
//        // Keyed by date "03/04/2018"
//        // Value: Array of dictionaries
//        // Dictionaries: ["category":cat, length:(minutes), start_time:(1015), description:(string), location:(string)
      }
      catch {
        print(error)
        print("Error!")
      }
//      if let jsonDict = JSONSerialization.jsonObject(with: unwrappedData)  {
//        print(jsonDict)
//      }
    }
    task.resume()
  }
  
}


// This is used to compartmentalize creating objects out of dictionaries...
extension DataController {
  /*        let jsonDict = try JSONSerialization.jsonObject(with: unwrappedData) as! [String: Any]
   let prayerPartners = jsonDict["prayer_partners"] as! [[String: Any]]
   print(prayerPartners)
   // index 0. general info? = key:"nav" value:"Prayer Partners"
   //                          key:"icon" value:"ic_group"
   
   // index 1-8 Partners = key:"students" value:"First Last\nFirst Last..."

 */
  func generatePrayerPartnerModel(from partnerGroups: [[String: Any]]) {
    let prayerPartnerGroupEntityName = "PrayerPartnerGroup"
    deleteAll(forEntityName: prayerPartnerGroupEntityName)

    //    let existingGroups = fetchAllEntities(forName: "PrayerPartnerGroup") as! [PrayerPartnerGroup]
    var prayerPartnersKVPairs = [String: String]()
    var createdGroups = [NSManagedObject]()
    for obj in partnerGroups {
      if let partnerNames = obj["students"] {
        if let createdGroup = createObject(prayerPartnerGroupEntityName, with: ["students": partnerNames]) {
          createdGroups.append(createdGroup)
        }
      }
      else if let navName = obj[sidebarNameKey] as? String {
        prayerPartnersKVPairs[sidebarNameKey] = navName
        if let iconName = obj[sidebarIconKey] as? String {
          prayerPartnersKVPairs[sidebarIconKey] = iconName
        }
      }
    }
    prayerPartnersKVPairs[orderKey] = "4"
    _ = createObject(sidebarAppearanceEntityName, with: prayerPartnersKVPairs)
  }
  
  func generateContactModel(from contacts: [String: Any]) {
    let contactEntityName = "Contact"
    deleteAll(forEntityName: contactEntityName)
    
    var createdContacts = [NSManagedObject]()
    for (key, value) in contacts {
      var kvDict = value as! [String:Any]
      kvDict["name"] = key
      if let createdContact = createObject(contactEntityName, with: kvDict) {
        createdContacts.append(createdContact)
      }
    }
    print(createdContacts)
  }
  
  func generateHousingModel(from housingDict: [String: Any]) {
    let housingEntityName = "HousingUnit"
    deleteAll(forEntityName: housingEntityName)
    
    var housingKVPairs = [String: String]()
    var createdHouses = [NSManagedObject]()
    for (key, value) in housingDict where key != sidebarNameKey && key != sidebarIconKey {
      var kvDict = value as! [String:Any]
      kvDict["hostName"] = key
      if let createdHousingUnit = createObject(housingEntityName, with: kvDict) {
        createdHouses.append(createdHousingUnit)
      }
    }
    if let navName = housingDict[sidebarNameKey] as? String {
      housingKVPairs[sidebarNameKey] = navName
    }
    if let iconName = housingDict[sidebarIconKey] as? String {
      housingKVPairs[sidebarIconKey] = iconName
    }
    housingKVPairs[orderKey] = "3"
    _ = createObject(sidebarAppearanceEntityName, with: housingKVPairs)
  }
  
  func generateGeneralModel(from general: [String: Any]) {
    let generalEntityName = "General"
    deleteAll(forEntityName: generalEntityName)

    var newGeneral = general.filter { (key, _) -> Bool in
      if key != "logo" {
        return true
      }
      else {
        return false
      }
    }
    let logoImage = (general["logo"] as! String).data(using: .utf8)!
    newGeneral["logo"] = logoImage
    if let createdGeneral = createObject(generalEntityName, with: newGeneral) {
      print(createdGeneral)
    }
    
  }
  
  func generateContactPageModel(from contactPageDict: [String: Any]) {
//    deleteAll(forEntityName: contactPageEntityName)
    
    var contactPageKVPairs = [String: String]()
//    var createdHouses = [NSManagedObject]()
//    for (key, value) in contactPageDict where key != sidebarNameKey && key != "icon" {
//      var kvDict = value as! [String:Any]
//      kvDict["hostName"] = key
//      if let createdHousingUnit = createObject(contactPageEntityName, with: kvDict) {
//        createdHouses.append(createdHousingUnit)
//      }
//    }

    //    ALSO SECTIONS
    
    //    var createdGroups = [NSManagedObject]()
    //    for (key, value) in housingUnits where key != "nav" && key != "icon" {
    //      var kvDict = value as! [String:Any]
    //      kvDict["hostName"] = key
    //      if let createdHousingUnit = createObject(housingEntityName, with: kvDict) {
    //        createdHouses.append(createdHousingUnit)
    //      }
    //      else {
    //        // it is for nav
    //      }
    //    }

    if let navName = contactPageDict[sidebarNameKey] as? String {
      contactPageKVPairs[sidebarNameKey] = navName
    }
    if let iconName = contactPageDict[sidebarIconKey] as? String {
      contactPageKVPairs[sidebarIconKey] = iconName
    }
    contactPageKVPairs[orderKey] = "1"
    _ = createObject(sidebarAppearanceEntityName, with: contactPageKVPairs)
  }
  
  func generateInformationPageModel(from informationPageDict: [String: Any]) {
//    deleteAll(forEntityName: informationPageEntityName)
    
    var pageNum = 0
    for (key, value) in (informationPageDict as! [String: [[String: Any]]]) {
      let pageIdentifier = key
      let sidebarName = value[0][sidebarNameKey] as! String
      let sidebarIconName = value[0][sidebarIconKey] as! String
      let kvDict = ["optionalIdentifier": pageIdentifier, sidebarNameKey: sidebarName, sidebarIconKey: sidebarIconName, orderKey: String(5+pageNum)]
      pageNum += 1
     _ = createObject(sidebarAppearanceEntityName, with: kvDict)
    }
  }
  
  func generateSchedulePageModel(from schedulePageDict: [String: Any]) {
//    deleteAll(forEntityName: schedulePageEntityName)
    let kvDict = [sidebarNameKey: schedulePageDict[sidebarNameKey]!, sidebarIconKey: schedulePageDict[sidebarIconKey]!, orderKey: "2"]
    _ = createObject(sidebarAppearanceEntityName, with: kvDict)
  }
  
  /// <#Description#>
  ///
  /// - Parameters:
  ///   - entityName: <#entityName description#>
  ///   - keyValuePairs: <#keyValuePairs description#>
  /// - Returns: The created object, or nil if the creation or save failed.
  func createObject(_ entityName: String, with keyValuePairs: [String: Any]) -> NSManagedObject? {
    let managedContext = persistentContainer.viewContext
    
    let entity = NSEntityDescription.entity(forEntityName: entityName,
                                            in: managedContext)!
    
    let object = NSManagedObject(entity: entity,
                                 insertInto: managedContext)
    
    object.setValuesForKeys(keyValuePairs)
    
    do {
      try managedContext.save()
      return object
    } catch let error as NSError {
      print("Could not save. \(error), \(error.userInfo)")
      return nil
    }
  }
  
  func fetchAllObjects(forName entityName: String) -> [NSManagedObject]? {

    let managedContext = persistentContainer.viewContext
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
    do {
      let entities = try managedContext.fetch(fetchRequest)
      print(entities)
      return entities
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
      return nil
    }
  }
  
  func deleteAllObjects() {
    let dataModelEntities = persistentContainer.managedObjectModel.entitiesByName.keys
    for entityName in dataModelEntities {
      deleteAll(forEntityName: entityName)
    }
  }

  func deleteAll(forEntityName entityName: String) {
    let managedContext = persistentContainer.viewContext
    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    let request = NSBatchDeleteRequest(fetchRequest: fetch)
    do {
      try managedContext.execute(request)
      try managedContext.save()
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
  }

}
