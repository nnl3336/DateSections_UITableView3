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
    var context: NSManagedObjectContext!
        var fetchedResultsController: NSFetchedResultsController<Folder>!

        private let tableView = UITableView()
        var didSelectFolder: ((Folder) -> Void)?
    
        var folders: [Folder] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            setupTableView()
            setupFetchedResultsController()
            try? fetchedResultsController.performFetch()
        }
    
    private func setupFetchedResultsController() {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
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

    func fetchFolders() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            var fetched = try context.fetch(request)

            // デフォルトフォルダ（存在しなければ追加）
            let defaultFolders: [(name: String, icon: String)] = [
                ("Memo", "note.text"),
                ("Trash", "trash")
            ]

            var needsSave = false
            for def in defaultFolders {
                if !fetched.contains(where: { $0.folderName == def.name }) {
                    let folder = Folder(context: context)
                    folder.folderName = def.name
                    folder.isDefault = true
                    folder.createdAt = Date()
                    needsSave = true
                    fetched.append(folder)  // いったん最後に追加
                }
            }

            if needsSave {
                try context.save()
            }

            // 並び替え：Memoが先頭、Trashは末尾、残りはそのまま
            folders = fetched.sorted { a, b in
                if a.folderName == "Memo" {
                    return true   // aを先頭に
                }
                if b.folderName == "Memo" {
                    return false  // bを先頭に
                }
                if a.folderName == "Trash" {
                    return false  // aを最後に
                }
                if b.folderName == "Trash" {
                    return true   // bを最後に
                }
                // それ以外は作成日時の昇順
                return (a.createdAt ?? Date()) < (b.createdAt ?? Date())
            }

            tableView.reloadData()

        } catch {
            print("Failed to fetch folders:", error)
        }
    }

}

//

extension SlideMenuViewController: NSFetchedResultsControllerDelegate {
    
}

extension SlideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FolderCell.reuseIdentifier,
            for: indexPath
        ) as! FolderCell

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
