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



