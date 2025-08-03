//
//  extension.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI

extension DateGroupedTableViewController {
    func groupMessagesByDate() {
        let groupedDict = Dictionary(grouping: messages) { message in
            Calendar.current.startOfDay(for: message.date ?? Date())
        }
        groupedMessages = groupedDict
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }
}


extension UIViewController {
    func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true

        let labelWidth = view.frame.size.width * 0.7
        toastLabel.frame = CGRect(x: (view.frame.size.width - labelWidth) / 2,
                                  y: view.frame.size.height - 120,
                                  width: labelWidth,
                                  height: 35)

        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}

