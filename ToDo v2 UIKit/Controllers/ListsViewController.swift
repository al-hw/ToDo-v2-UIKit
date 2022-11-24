//
//  ListsViewController.swift
//  ToDo v2 UIKit
//
//  Created by Alex Hwan on 18.11.2022.
//

import UIKit
import CoreData

class ListsViewController: UITableViewController {
    
    private var frc: NSFetchedResultsController<Lists>!
    private let context = CoreDataManager.sharedManager.persistentContainer.viewContext
    
    let dateFormatter = DateFormatter()
    
    private func configureNavBar() {
        navigationItem.title = "ToDo"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addListTapped))
    }
    
    private func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: K.List.listCellIdentifier)
    }
    
    private func setupListsFRC() {
        frc = CoreDataManager.sharedManager.loadListsFRC()
        frc.delegate = self
        
        do {
            try frc.performFetch()
            tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        configureTableView()
        configureNavBar()
        setupListsFRC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    //MARK: - Add Button Tapped
    
    @objc func addListTapped() {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New List", message: "", preferredStyle: .alert)
        let addCategoryAction = UIAlertAction(title: "Add", style: .default) { action in
            
            let newCategory = Lists(context: self.context)
            
            if textField.text != "" {
                newCategory.name = textField.text
                newCategory.timeStamp = Date().timeIntervalSince1970
                newCategory.dateSections = self.dateFormatter.string(from: Date().startOfDay())
            }
        }
        
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "New list name"
            textField = alertTextField
        }
        
        alert.addAction(addCategoryAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in }))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - ListsViewController DataSource
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = frc?.sections![section]
        let lists = sectionInfo?.objects
        
        if let list: NSManagedObject = lists?[0] as? NSManagedObject {
            let listDate = list.value(forKey: K.List.listAttributeDateSections) as? String
            return listDate
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        20
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = frc?.sections![section]
        return sectionInfo?.numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.List.listCellIdentifier, for: indexPath)
        
        let list = frc.object(at: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = list.name
        
        if list.childItems?.count != 0 {
            content.image = UIImage(systemName: "folder.fill")?.withTintColor(.label, renderingMode: .alwaysOriginal)
            content.secondaryText = "\(list.childItems?.count ?? 0) items in the list"
        } else {
            content.image = UIImage(systemName: "folder")?.withTintColor(.label, renderingMode: .alwaysOriginal)
            content.secondaryText = "Empty list"
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.contentConfiguration = content
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = ItemsViewController()
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedList = frc.object(at: indexPath)
        }
        navigationController?.pushViewController(destinationVC, animated: true)
    }
    
    //MARK: - Swipe Actions
    
    //Delete
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, complete) in
            
            let alert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            
            let deleteListAction = UIAlertAction(title: "Delete", style: .default) { action in
                let list = self.frc.object(at: indexPath)
                self.context.delete(list)
            }
            deleteListAction.setValue(UIColor.red, forKey: "titleTextColor")
            
            alert.addAction(deleteListAction)
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
            
            let list = self.frc.object(at: indexPath)
            
            var textField = UITextField()
            let alert = UIAlertController(title: "Edit List", message: "", preferredStyle: .alert)
            
            let editListAction = UIAlertAction(title: "Save", style: .default) { action in
                list.name = textField.text
                tableView.reloadData()
            }
            
            let editListCancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addTextField { alertTextField in
                alertTextField.text = list.value(forKey: K.List.listAttributeName) as? String
                textField = alertTextField
            }
            
            alert.addAction(editListAction)
            alert.addAction(editListCancelAction)
            
            self.present(alert, animated: true, completion: nil)
            complete(true)
        }
        
        editAction.backgroundColor = .blue
        editAction.image = UIImage(systemName: "pencil.line")
        
        let configuration = UISwipeActionsConfiguration(actions: [editAction])
        
        return configuration
    }
}

//MARK: - FetchResultsController Delegates

extension ListsViewController: NSFetchedResultsControllerDelegate {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc?.sections?.count ?? 0
    }
    
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
    
    //Sections Controller
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let section = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(section, with: .fade)
        case .delete:
            tableView.deleteSections(section, with: .fade)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

//MARK: - Date Modification for Sections

extension Date {
    func startOfDay() -> Date {
        
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components)!
    }
}
