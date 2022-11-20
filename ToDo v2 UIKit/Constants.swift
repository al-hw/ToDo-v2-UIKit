//
//  Constants.swift
//  ToDo v2 UIKit
//
//  Created by Alex Hwan on 19.11.2022.
//

struct K {
    static let modelName = "ToDo_v2_UIKit"
    
    struct List {
        static let listCellIdentifier = "ListsViewCell"
        static let listEntity = "Lists"
        static let listAttributeTimeStamp = "timeStamp"
        static let listAttributeName = "name"
        static let listAttributeDateSections = "dateSections"
    }
    
    struct Item {
        static let itemCellIdentifier = "itemCell"
        static let itemAttributeTitle = "name"
        static let itemAttributeTimeStamp = "timeStamp"
        static let itemAttributeDone = "done"
        static let itemParentListPredicate = "parentList.name MATCHES %@"
        static let itemSearchBarPredicate = "name CONTAINS[cd] %@"
    }
}
