//
//  CoreDataManager.swift
//  ToDo v2 UIKit
//
//  Created by Alex Hwan on 19.11.2022.

import UIKit
import CoreData

class CoreDataManager {
    
    static let sharedManager = CoreDataManager(modelName: K.modelName)
    
    let persistentContainer: NSPersistentContainer
    
    private lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let nserror = error as NSError? {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func loadListsFRC() -> NSFetchedResultsController<Lists> {
        let request = Lists.fetchRequest()
        let sort = NSSortDescriptor(key: K.List.listAttributeTimeStamp, ascending: false)
        
        request.sortDescriptors = [sort]
        request.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: K.List.listAttributeDateSections, cacheName: nil)
    }
    
    func loadItemsFRC(with request: NSFetchRequest<Items> = Items.fetchRequest(), predicate: NSPredicate? = nil, selectedList: Lists? = nil) -> NSFetchedResultsController<Items> {
        let request = Items.fetchRequest()
        
        let sortByDone = NSSortDescriptor(key: K.Item.itemAttributeDone, ascending: true)
        let sortByTimeStamp = NSSortDescriptor(key: K.Item.itemAttributeTimeStamp, ascending: false)
        
        request.sortDescriptors = [sortByDone, sortByTimeStamp]
        request.fetchBatchSize = 20
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 10
        formatter.roundingMode = .floor
        
        let selectedListTimeStampPredicate = formatter.string(from: NSNumber(value: selectedList!.timeStamp))
        
        let listPredicate = NSPredicate(format: K.Item.itemParentListPredicate, selectedListTimeStampPredicate!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [listPredicate, additionalPredicate])
        } else {
            request.predicate = listPredicate
        }
     
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
}


