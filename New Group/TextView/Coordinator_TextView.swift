//
//  Coordinator_TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/05.
//

import Foundation

class DetailViewCoordinator: NSObject {
    weak var viewController: DetailViewController?

    init(viewController: DetailViewController) {
        self.viewController = viewController
        super.init()
    }
    
    //***


    @objc func saveText() {
        print("Save text action")
    }

    @objc func showImagePicker() {
        print("Show image picker")
    }

    @objc func toggleLike() {
        print("Toggle like")
    }

    @objc func toggleCheck() {
        print("Toggle check")
    }

    @objc func copyText() {
        print("Copy text")
    }

    @objc func createNewPost() {
        print("Create new post")
    }
}
