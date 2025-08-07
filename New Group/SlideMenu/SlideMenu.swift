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
    var folders: [Folder] = []
    var didSelectFolder: ((Folder) -> Void)?

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupTableView()

        // ここでデフォルトフォルダを確実に作成してから fetch
        ensureDefaultFoldersIfNeeded { [weak self] in
            self?.fetchFolders()
        }
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FolderCell.self, forCellReuseIdentifier: FolderCell.reuseIdentifier)
        tableView.rowHeight = 50
        view.addSubview(tableView)
    }

    // MARK: - Fetch
    func fetchFolders() {
        guard context != nil else { return }
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        context.perform { [weak self] in
            do {
                let result = try self?.context.fetch(request) ?? []
                DispatchQueue.main.async {
                    self?.folders = result
                    self?.tableView.reloadData()
                }
            } catch {
                print("Failed to fetch folders:", error)
            }
        }
    }

    // MARK: - Ensure default folders
    private func ensureDefaultFoldersIfNeeded(completion: @escaping () -> Void) {
        guard context != nil else {
            completion()
            return
        }

        // デフォルトフォルダ名の配列
        let defaultNames = ["もめも", "とらっしゅ"]

        context.perform { [weak self] in
            guard let self = self else { return }

            // 既にデフォルトのいずれかが存在するか確認する（重複防止）
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.predicate = NSPredicate(format: "name IN %@", defaultNames)
            do {
                let existing = try self.context.fetch(request).compactMap { $0.folderName }
                var didCreate = false

                for name in defaultNames {
                    if !existing.contains(name) {
                        let folder = Folder(context: self.context)
                        folder.folderName = name
                        folder.createdAt = Date()
                        folder.isDefault = true
                        didCreate = true
                    }
                }

                if didCreate {
                    try self.context.save()
                }
            } catch {
                print("Error ensuring default folders:", error)
            }

            // 完了ハンドラ（UI 更新は呼び出し元で行う）
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

//

extension SlideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.reuseIdentifier, for: indexPath) as! FolderCell
        let folder = folders[indexPath.row]
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
