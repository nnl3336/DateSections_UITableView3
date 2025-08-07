//
//  SlideMenu.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/08.
//

import SwiftUI

class SlideMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var folders: [String] = ["Work", "Personal", "Archive", "Trash"]
    var didSelectFolder: ((String) -> Void)?

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupTableView()
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = folders[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectFolder?(folders[indexPath.row])
    }
}
