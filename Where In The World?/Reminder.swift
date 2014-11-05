//
//  Reminder.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/4/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import Foundation
import CoreData

@objc (Reminder)
class Reminder: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var createdAt: NSDate
    @NSManaged var radius: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

}
