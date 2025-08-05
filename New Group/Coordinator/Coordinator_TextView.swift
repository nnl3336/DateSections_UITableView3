//
//  Coordinator_TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/05.
//

import Foundation
import UIKit

//

import PhotosUI

extension DetailViewCoordinator: PHPickerViewControllerDelegate {

    @objc func showImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0  // 0は無制限、複数選択OK
        config.filter = .images    // 画像のみ選択可能にする

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self

        viewController?.present(picker, animated: true)
    }

    // 選択完了時のコールバック
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let itemProviders = results.map { $0.itemProvider }
        var images: [UIImage] = []

        let group = DispatchGroup()

        for item in itemProviders {
            if item.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                item.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            // ここで画像配列(images)を扱う
            self.viewController?.handleSelectedImages(images)
        }
    }
}

//

// 使わない

class DetailViewCoordinator: NSObject {
    weak var viewController: DetailViewController?

    init(viewController: DetailViewController) {
        self.viewController = viewController
        super.init()
    }
    
    //***

    /*@objc func saveText() {
        print("Save text action")
    }

    // -showImagePicker     // 🔻 showImagePicker() は削除！


    @objc func toggleLike() {
        print("Toggle like Coordinator")
        guard let vc = viewController else { return }
        vc.ep_textView.selectLiked.toggle()
        vc.buttonLike.image = UIImage(
            systemName: vc.ep_textView.selectLiked ? "heart.fill" : "heart"
        )
    }

    @objc func toggleCheck() {
        print("Toggle check Coordinator")
        guard let vc = viewController else { return }
        vc.ep_textView.selectCheck.toggle()
        vc.buttonCheck.image = UIImage(
            systemName: vc.ep_textView.selectCheck ? "checkmark.circle.fill" : "checkmark.circle"
        )
    }

    @objc func copyText() {
        print("Copy text")
    }

    @objc func createNewPost() {
        print("Create new post")
    }*/
}
