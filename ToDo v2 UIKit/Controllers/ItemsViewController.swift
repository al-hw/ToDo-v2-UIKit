//
//  ItemsViewController.swift
//  ToDo v2 UIKit
//
//  Created by Alex Hwan on 19.11.2022.
//

import UIKit
import CoreData

class ItemsViewController: UITableViewController {
    
    private var frc: NSFetchedResultsController<Items>!
    private let context = CoreDataManager.sharedManager.persistentContainer.viewContext
    
    let dateFormatter = DateFormatter()
    
    var selectedList : Lists? {
        didSet{
            loadItems()
        }
    }
    
    private func configureNavBar() {
        navigationItem.title = selectedList?.name
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addItemTapped))
        
        let searchBar = UISearchController(searchResultsController: nil)
        searchBar.searchBar.delegate = self
        navigationItem.searchController = searchBar
    }
    
    private func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: K.Item.itemCellIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBar()
        configureTableView()
        
        dateFormatter.dateStyle = .long
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
            navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    // MARK: - TableView DataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc?.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.Item.itemCellIdentifier, for: indexPath)
        
        let item = frc.object(at: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = item.name
        content.textProperties.color = item.done ? .gray : .label
        
        let doneImage = UIImage(systemName: "checkmark.circle")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        let notDoneImage = UIImage(systemName: "circle")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        
        content.image = item.done ? doneImage : notDoneImage
        
//        cell.accessoryType = item.done ? .checkmark : .none
//        cell.tintColor = .label
        cell.contentConfiguration = content
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        frc.object(at: indexPath).done = !frc.object(at: indexPath).done
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - DataModel Methods
    
    func loadItems(with request: NSFetchRequest<Items> = Items.fetchRequest(), predicate: NSPredicate? = nil) {
        
        if frc == nil {
            let request = Items.fetchRequest()
            
            let sortByDone = NSSortDescriptor(key: K.Item.itemAttributeDone, ascending: true)
            let sortByTimeStamp = NSSortDescriptor(key: K.Item.itemAttributeTimeStamp, ascending: false)
            request.sortDescriptors = [sortByDone, sortByTimeStamp]
            request.fetchBatchSize = 20
            
            let listPredicate = NSPredicate(format: K.Item.itemParentListPredicate, selectedList!.name!)
            if let additionalPredicate = predicate {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [listPredicate, additionalPredicate])
            } else {
                request.predicate = listPredicate
            }
            
            frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            frc.delegate = self
        }
        
        do {
            try frc.performFetch()
            tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Add Item Tapped
    
    @objc func addItemTapped() {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)
        
        let addItemAction = UIAlertAction(title: "Add", style: .default) { action in
            
            let newItem = Items(context: self.context)
            
            if textField.text != "" {
                newItem.done = false
                newItem.name = textField.text!
                newItem.timeStamp = Int32(Date().timeIntervalSince1970)
                newItem.parentList = self.selectedList
                
                // Under consideration (update edit date to list?):
                // newItem.parentList?.timeStamp = Date().timeIntervalSince1970
                // newItem.parentList?.dateSections = self.dateFormatter.string(from: Date().startOfDay())
            }
        }
        
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Enter new item text"
            textField = alertTextField
        }
        
        alert.addAction(addItemAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in }))
        
        present(alert, animated: true, completion: nil)
    }
    

    //MARK: - Swipe Actions
    
    //Delete
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, complete) in

            let alert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            
            let deleteItemAction = UIAlertAction(title: "Delete", style: .default) { action in
                let item = self.frc.object(at: indexPath)
                self.context.delete(item)
            }
            deleteItemAction.setValue(UIColor.red, forKey: "titleTextColor")
            
            alert.addAction(deleteItemAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            complete(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    //Edit
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
            
            let item = self.frc.object(at: indexPath)
            
            var textField = UITextField()
            
            let alert = UIAlertController(title: "Edit Item", message: "", preferredStyle: .alert)
            
            let editItemAction = UIAlertAction(title: "Edit", style: .default) { action in
                item.done = false
                item.name = textField.text!
                item.timeStamp = Int32(Date().timeIntervalSince1970)
                
                tableView.reloadData()
            }
            
            alert.addTextField { alertTextField in
                alertTextField.text = item.name
                textField = alertTextField
            }
            
            alert.addAction(editItemAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in }))
            
            self.present(alert, animated: true, completion: nil)
            
            complete(true)
        }
        
        editAction.backgroundColor = .blue
        editAction.image = UIImage(systemName: "pencil.line")
        
        let configuration = UISwipeActionsConfiguration(actions: [editAction])
        
        return configuration
    }
}

//MARK: - SearchBar Methods

extension ItemsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let request = Items.fetchRequest()
        let predicate = NSPredicate(format: K.Item.itemSearchBarPredicate, searchBar.text!)
        
        request.sortDescriptors = [NSSortDescriptor(key: K.Item.itemAttributeTitle, ascending: true)]
        
        frc = nil
        loadItems(with: request, predicate: predicate)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            
            frc = nil
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}

//MARK: - FetchResultsController Delegates

extension ItemsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    //Cells controller
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
