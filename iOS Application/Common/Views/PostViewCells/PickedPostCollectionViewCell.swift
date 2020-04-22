//
//  PickedPostCollectionViewCell.swift
//  Basem Emara
//
//  Created by Basem Emara on 2018-06-25.
//  Copyright © 2018 Zamzam Inc. All rights reserved.
//

import UIKit
import SwiftyPress
import ZamzamCore

final class PickedPostCollectionViewCell: UICollectionViewCell {
    
    private let titleLabel = ThemedHeadline().with {
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 2
    }
    
    private let summaryLabel = ThemedSubhead().with {
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.numberOfLines = 3
    }
    
    private let featuredImage = ThemedImageView(imageNamed: .placeholder).with {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private lazy var favoriteButton = ThemedImageButton().with {
        $0.setImage(UIImage(named: .favoriteEmpty), for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.addTarget(self, action: #selector(didTapFavoriteButton), for: .touchUpInside) // Must be in lazy init
    }
    
    private var model: PostsDataViewModel?
    private weak var delegate: PostsDataViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension PickedPostCollectionViewCell {
    
    func prepare() {
        let favoriteView = UIView().with {
            $0.backgroundColor = .clear
            $0.addSubview(favoriteButton)
        }
        
        let stackView = UIStackView(arrangedSubviews: [
            featuredImage,
            UIStackView(arrangedSubviews: [
                titleLabel.with {
                    $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
                },
                summaryLabel,
                favoriteView
            ]).with {
                $0.axis = .vertical
                $0.spacing = 5
            }
        ]).with {
            $0.axis = .horizontal
            $0.spacing = 8
        }
        
        let view = ThemedView().with {
            $0.addSubview(stackView)
        }
        
        addSubview(view)
        
        view.edges(to: self)
        stackView.edges(to: view, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16))
        
        featuredImage.aspectRatioSize()
        
        favoriteView.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        favoriteButton.center()
    }
}

// MARK: - Interactions

private extension PickedPostCollectionViewCell {
    
    @objc func didTapFavoriteButton() {
        favoriteButton.isSelected.toggle()
        guard let model = model else { return }
        delegate?.postsDataView(toggleFavorite: model)
    }
}

// MARK: - Delegates

extension PickedPostCollectionViewCell: PostsDataViewCell {
    
    func load(_ model: PostsDataViewModel) {
        self.model = model
        
        titleLabel.text = model.title
        summaryLabel.text = model.summary
        featuredImage.setImage(from: model.imageURL)
        favoriteButton.isSelected =  model.favorite ?? false
    }
    
    func load(_ model: PostsDataViewModel, delegate: PostsDataViewDelegate?) {
        self.delegate = delegate
        load(model)
    }
}
