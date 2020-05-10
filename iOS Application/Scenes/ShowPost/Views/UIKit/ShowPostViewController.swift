//
//  ShowPostViewController.swift
//  Basem Emara
//
//  Created by Basem Emara on 2018-10-01.
//  Copyright © 2018 Zamzam Inc. All rights reserved.
//

import UIKit
import WebKit
import SystemConfiguration
import SwiftyPress
import ZamzamCore
import ZamzamUI

class ShowPostViewController: UIViewController, StatusBarable {
    private let store: Store<ShowPostState>
    private let interactor: ShowPostInteractorType?
    private let constants: Constants
    private let theme: Theme
    private let notificationCenter: NotificationCenter
    private var cancellable: NotificationCenter.Cancellable?
    
    private var postID: Int?
    private var viewModel: ShowPostAPI.PostViewModel?
    private var history: [Int] = []
    
    let application: UIApplication
    var statusBar: UIView?
    var render: ShowPostRenderType?
    
    // MARK: - Controls
    
    private lazy var webView = WKWebView().apply {
        $0.navigationDelegate = self
        $0.scrollView.delegate = self
        $0.scrollView.contentInset.bottom += 60
        $0.backgroundColor = theme.backgroundColor
        
        // Workaround for initial flash
        // https://stackoverflow.com/a/35121664
        $0.isOpaque = false
    }
    
    private lazy var favoriteBarButton = UIBarButtonItem(
        imageName: UIImage.ImageName.favoriteEmpty.rawValue,
        target: self,
        action: #selector(favoriteTapped)
    )
    
    private lazy var commentBarButton = BadgeBarButtonItem(
        image: UIImage(named: .comments),
        badgeText: nil,
        target: self,
        action: #selector(commentsTapped)
    )
    
    private lazy var toolbarButtons = [
        UIBarButtonItem(imageName: "back", target: self, action: #selector(backTapped)),
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        commentBarButton,
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        favoriteBarButton,
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped(_:)))
    ]
    
    private lazy var activityIndicatorView = view.makeActivityIndicator()
    
    // MARK: - Initializers
    
    init(
        store: Store<ShowPostState>,
        interactor: ShowPostInteractorType?,
        constants: Constants,
        theme: Theme,
        application: UIApplication,
        notificationCenter: NotificationCenter,
        postID: Int
    ) {
        self.store = store
        self.interactor = interactor
        self.constants = constants
        self.theme = theme
        self.application = application
        self.notificationCenter = notificationCenter
        self.postID = postID
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true // Must be done in initialization
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepare()
        fetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isToolbarHidden = false
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
        navigationController?.hidesBarsOnSwipe = false
    }
}

// MARK: - Setup

private extension ShowPostViewController {
    
    func prepare() {
        // Configure controls
        toolbarItems = toolbarButtons
        
        // Compose layout
        view.addSubview(webView)
        webView.edges(to: view)
        
        // Status bar background transparent so fill on scroll
        showStatusBar()
        notificationCenter.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification
        )
        
        // Bind state
        store(in: &cancellable, observer: load)
    }
    
    func fetch() {
        guard let postID = postID else { return }
        activityIndicatorView.startAnimating()
        
        interactor?.fetchPost(
            with: ShowPostAPI.Request(postID: postID)
        )
    }
}

private extension ShowPostViewController {
    
    func load(_ state: ShowPostState) {
        if let web = state.web {
            load(web)
        }
        
        if let post = state.post {
            load(post)
        }
        
        load(favorite: state.favorite)
    }
    
    func load(_ viewModel: ShowPostAPI.PostViewModel) {
        self.viewModel = viewModel
        
        title = viewModel.title
        commentBarButton.badgeText = "\(viewModel.commentCount)"
        load(favorite: viewModel.favorite)
        
        webView.loadHTMLString(
            viewModel.content,
            baseURL: constants.baseURL
        )
    }
    
    func load(_ viewModel: ShowPostAPI.WebViewModel) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        
        if let postID = viewModel.postID {
            load(postID)
            return viewModel.decisionHandler(.cancel)
        }
        
        if let termID = viewModel.termID {
            render?.listPosts(params: .init(fetchType: .terms([termID])))
            return viewModel.decisionHandler(.cancel)
        }
        
        title = nil
        activityIndicatorView.startAnimating()
        viewModel.decisionHandler(.allow)
    }
    
    func load(favorite: Bool) {
        favoriteBarButton.image = favorite
            ? UIImage(named: .favoriteFilled)
            : UIImage(named: .favoriteEmpty)
    }
}

extension ShowPostViewController: ShowPostLoadable {
    
    func load(_ id: Int) {
        if let lastPostID = postID {
            history.append(lastPostID)
        }
        
        postID = id
        fetch()
    }
}

// MARK: - Interactions

private extension ShowPostViewController {
    
    @objc func favoriteTapped() {
        guard let postID = postID else { return }
        
        interactor?.toggleFavorite(
            with: ShowPostAPI.FavoriteRequest(
                postID: postID
            )
        )
    }
    
    @objc func commentsTapped() {
        guard SCNetworkReachability.isOnline else {
            present(
                alert: .localized(.commentsNotAvailableErrorTitle),
                message: .localized(.notConnectedToInternetErrorMessage)
            )
            
            return
        }
        
        let url = constants.baseURL
            .appendingPathComponent("mobile-comments")
            .appendingQueryItem("postid", value: postID)
            .absoluteString
        
        render?.show(url: url)
    }
    
    @objc func shareTapped(_ sender: UIBarButtonItem) {
        guard let title = viewModel?.title,
            let link = viewModel?.link,
            let url = URL(string: link) else {
                return
        }
        
        let safariActivity = UIActivity.make(
            title: .localized(.openInSafari),
            imageName: UIImage.ImageName.safariShare.rawValue,
            handler: {
                guard SCNetworkReachability.isOnline else {
                    self.present(
                        alert: .localized(.browserNotAvailableErrorTitle),
                        message: .localized(.notConnectedToInternetErrorMessage)
                    )
                    
                    return
                }

                self.application.open(url)
            }
        )
        
        present(
            activities: [title.htmlDecoded, link],
            barButtonItem: sender,
            applicationActivities: [safariActivity]
        )
    }
    
    @objc func backTapped() {
        guard let lastPostID = history.popLast() else {
            present(alert: .localized(.noPostInHistoryErrorMessage))
            return
        }
        
        activityIndicatorView.startAnimating()
        postID = lastPostID
        
        interactor?.fetchPost(
            with: ShowPostAPI.Request(postID: lastPostID)
        )
    }
    
    @objc func deviceOrientationDidChange() {
        resetStatusBar()
    }
}

// MARK: - Delegates

extension ShowPostViewController: ListPostsDelegate {
    
    func listPosts(_ viewController: UIViewController, didSelect postID: Int) {
        load(postID)
        viewController.dismissOrPop()
    }
}

extension ShowPostViewController: WKNavigationDelegate {
    //swiftlint:disable implicitly_unwrapped_optional
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let requestURL = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
            return decisionHandler(.allow)
        }
        
        // Open same domain links within app
        guard requestURL.host == constants.baseURL.host else {
            // Open external links in browser
            render?.show(url: requestURL.absoluteString)
            return decisionHandler(.cancel)
        }
        
        interactor?.fetchByURL(
            with: ShowPostAPI.FetchWebRequest(
                url: requestURL.absoluteString,
                decisionHandler: decisionHandler
            )
        )
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()
    }
}

extension ShowPostViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Display navigation/toolbar when scrolled to the bottom
        guard scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) else { return }
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
    }
}
