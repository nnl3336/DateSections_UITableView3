//
//  CustomCell.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/04.
//

import SwiftUI

class CustomCell: UITableViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let folderLabel = UILabel()      // 下段のラベル
    let iconView = UIImageView()
    let likeButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // アイコン
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 20
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)

        // タイトルラベル（上）
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        contentView.addSubview(titleLabel)

        // サブタイトル（日付＋テキスト２）（中）
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)

        // フォルダラベル（下）
        folderLabel.translatesAutoresizingMaskIntoConstraints = false
        folderLabel.font = UIFont.systemFont(ofSize: 13)
        folderLabel.textColor = .gray
        contentView.addSubview(folderLabel)

        // Likeボタン
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.tintColor = .gray
        contentView.addSubview(likeButton)

        // Auto Layout
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            folderLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            folderLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),
            folderLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            folderLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            likeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 24),
            likeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func updateLikeButton(isLiked: Bool) {
        let imageName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
        likeButton.tintColor = isLiked ? .systemRed : .gray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
