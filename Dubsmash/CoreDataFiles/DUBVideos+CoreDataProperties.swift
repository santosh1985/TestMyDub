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

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<DUBVideos>(entityName: "DUBVideos") as! NSFetchRequest<NSFetchRequestResult>
    }

    @NSManaged public var fileName: String?

}
