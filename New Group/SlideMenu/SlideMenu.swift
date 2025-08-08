//
//  SlideMenu.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/08.
//

import SwiftUI
import CoreData
import UIKit

class SlideMenuViewController: UIViewController {
    // MARK: - Properties

    var context: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<Folder>!

    private let tableView = UITableView()
    var didSelectFolder: ((Folder) -> Void)?

    private var visibleFolders: [Folder] = []
    private var expandedFolderIDs = Set<NSManagedObjectID>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFetchedResultsController()
        try? fetchedResultsController.performFetch()
        checkAndAddDefaultFoldersIfNeeded()
        reloadVisibleFolders()
    }

    // MARK: - Setup Methods 

    private func setupFetchedResultsController() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FolderCell.self, forCellReuseIdentifier: FolderCell.reuseIdentifier)
        tableView.rowHeight = 50
        view.addSubview(tableView)
    }

    // MARK: - Default Folders Check

    private func checkAndAddDefaultFoldersIfNeeded() {
        guard let folders = fetchedResultsController.fetchedObjects else { return }

        let defaultFolders = [
            ("Memo", "note.text"),
            ("Trash", "trash")
        ]

        var needsSave = false
        for def in defaultFolders {
            if !folders.contains(where: { $0.folderName == def.0 }) {
                let folder = Folder(context: context)
                folder.folderName = def.0
                folder.isDefault = true
                folder.createdAt = Date()
                needsSave = true
            }
        }
        if needsSave {
            try? context.save()
            try? fetchedResultsController.performFetch()
        }
    }

    // MARK: - Folder Management

    func reloadVisibleFolders() {
        visibleFolders = []
        if let rootFolders = fetchedResultsController.fetchedObjects?.filter({ $0.parent == nil }) {
            for folder in rootFolders.sorted(by: { $0.createdAt ?? Date() < $1.createdAt ?? Date() }) {
                visibleFolders.append(folder)
                if expandedFolderIDs.contains(folder.objectID) {
                    appendChildren(of: folder)
                }
            }
        }
    }

    func appendChildren(of folder: Folder) {
        guard let childrenSet = folder.children as? Set<Folder> else { return }
        let sortedChildren = childrenSet.sorted(by: { $0.createdAt ?? Date() < $1.createdAt ?? Date() })
        for child in sortedChildren {
            visibleFolders.append(child)
            if expandedFolderIDs.contains(child.objectID) {
                appendChildren(of: child)
            }
        }
    }


    func getFolderLevel(_ folder: Folder) -> Int {
        var level = 0
        var current = folder
        while let parents = current.parent as? Set<Folder>, let firstParent = parents.first {
            level += 1
            current = firstParent
        }
        return level
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SlideMenuViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleFolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = visibleFolders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.reuseIdentifier, for: indexPath) as! FolderCell

        cell.indentationLevel = getFolderLevel(folder)

        switch folder.folderName {
        case "Trash":
            cell.configure(with: folder.folderName ?? "", iconName: "trash")
        case "Memo":
            cell.configure(with: folder.folderName ?? "", iconName: "note.text")
        default:
            cell.configure(with: folder.folderName ?? "", iconName: "folder")
        }

        if let childrenSet = folder.children as? Set<Folder>, !childrenSet.isEmpty {
            // childrenSetはSet<Folder>なのでisEmptyが使える
            cell.accessoryView = UIImageView(image: UIImage(systemName: expandedFolderIDs.contains(folder.objectID) ? "chevron.down" : "chevron.right"))
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = visibleFolders[indexPath.row]
        if let childrenSet = folder.children as? Set<Folder>, !childrenSet.isEmpty {
            if expandedFolderIDs.contains(folder.objectID) {
                expandedFolderIDs.remove(folder.objectID)
            } else {
                expandedFolderIDs.insert(folder.objectID)
            }
            reloadVisibleFolders()
            tableView.reloadData()
        } else {
            didSelectFolder?(folder)
        }
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension SlideMenuViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        reloadVisibleFolders()
        tableView.reloadData()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        @unknown default:
            break
        }
    }
}


/*
extension SlideMenuViewController {
    
    func setupDefaultFolders(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        if let count = try? context.count(for: request), count == 0 {
            let memo = Folder(context: context)
            memo.folderName = "Memo"
            memo.createdAt = Date()
            memo.isDefault = true
            
            let trash = Folder(context: context)
            trash.folderName = "Trash"
            trash.createdAt = Date()
            trash.isDefault = true
            
            try? context.save()
        }
    }
    
}
*/
