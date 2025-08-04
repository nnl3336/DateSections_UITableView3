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
    let iconView = UIImageView()
    let likeButton = UIButton(type: .system)  // 追加

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // アイコン
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 20
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)

        // タイトルラベル
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        contentView.addSubview(titleLabel)

        // サブタイトルラベル
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .gray
        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)

        // like ボタンの設定
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
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

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
