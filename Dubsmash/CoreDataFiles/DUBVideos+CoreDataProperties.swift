//
//  DUBVideos+CoreDataProperties.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/18/17.
//  Copyright © 2017 onest. All rights reserved.
//

import Foundation
import CoreData


extension DUBVideos {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DUBVideos> {
        return NSFetchRequest<DUBVideos>(entityName: "DUBVideos")
    }

    @NSManaged public var fileName: String?

}
