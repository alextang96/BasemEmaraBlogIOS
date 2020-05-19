//
//  SharedState.swift
//  BasemEmara iOS
//
//  Created by Basem Emara on 2020-05-19.
//  Copyright © 2020 Zamzam Inc. All rights reserved.
//

import SwiftyPress

class SharedState: StateRepresentable {
    
    private(set) var posts: [PostsDataViewModel] = [] {
        willSet {
            guard newValue != posts, #available(iOS 13, *) else { return }
            combineSend()
        }
        
        didSet {
            guard oldValue != posts else { return }
            notificationPost(keyPath: \SharedState.posts)
        }
    }
    
    private(set) var terms: [TermsDataViewModel] = [] {
        willSet {
            guard newValue != terms, #available(iOS 13, *) else { return }
            combineSend()
        }
        
        didSet {
            guard oldValue != terms else { return }
            notificationPost(keyPath: \SharedState.terms)
        }
    }
}

// MARK: - Action

enum SharedAction: Action {
    case mergePosts([PostsDataViewModel])
    case mergeTerms([TermsDataViewModel])
}

// MARK: - Reducer

extension SharedState {
    
    func reduce(_ action: SharedAction) {
        switch action {
        case .mergePosts(let items):
            let ids = items.map(\.id)
            posts = posts.filter { !ids.contains($0.id) } + items
        case .mergeTerms(let items):
            let ids = items.map(\.id)
            terms = terms.filter { !ids.contains($0.id) } + items
        }
    }
}

// MARK: - SwiftUI

#if canImport(SwiftUI)
import Combine

@available(iOS 13, *)
extension SharedState: ObservableObject {}
#endif
