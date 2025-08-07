//
//  SlideMenu.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/08.
//

import SwiftUI
import CoreData

class SlideMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var context: NSManagedObjectContext!
    var folders: [Folder] = []
    var didSelectFolder: ((Folder) -> Void)?

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupTableView()
        fetchFolders()
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FolderCell.self, forCellReuseIdentifier: FolderCell.reuseIdentifier)
        tableView.rowHeight = 50
        view.addSubview(tableView)
    }

    private func fetchFolders() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let result = try? context.fetch(request) {
            folders = result
            tableView.reloadData()
        }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.reuseIdentifier, for: indexPath) as! FolderCell
        let folder = folders[indexPath.row]

        // デフォルトフォルダはアイコンを変える
        if folder.isDefault {
            if folder.folderName == "Trash" {
                cell.configure(with: folder.folderName ?? "", iconName: "trash")
            } else {
                cell.configure(with: folder.folderName ?? "", iconName: "note.text")
            }
        } else {
            cell.configure(with: folder.folderName ?? "", iconName: "folder")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectFolder?(folders[indexPath.row])
    }
}

//

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
