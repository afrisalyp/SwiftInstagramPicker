//
//  ALImagePickerViewController.swift
//  ALImagePickerViewController
//
//  Created by Alex Littlejohn on 2015/06/09.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import Photos
import OAuthSwift

internal let ImageCellIdentifier = "ImageCell"

internal let defaultItemSpacing: CGFloat = 1

public typealias PhotoLibraryViewSelectionComplete = (media: IGMedia?) -> Void

public class PhotoLibraryViewController: UIViewController {
    
    private var assets: [IGMedia]? = nil
    public var onSelectionComplete: PhotoLibraryViewSelectionComplete?

    var clientId: String!
    var clientSecret: String!
    var redirectUrl: String!
    var redirectUrlScheme: String!
    
    let authorizeURL = "https://api.instagram.com/oauth/authorize"
    
    required public init(clientId: String, clientSecret: String, redirectUrl: String, redirectUrlScheme: String){
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUrl = redirectUrl
        self.redirectUrlScheme = redirectUrlScheme
        super.init(nibName:nil, bundle:nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        layout.itemSize = CameraGlobals.shared.photoLibraryThumbnailSize
        layout.minimumInteritemSpacing = defaultItemSpacing
        layout.minimumLineSpacing = defaultItemSpacing
        layout.sectionInset = UIEdgeInsetsZero
      
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.whiteColor()
        return collectionView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setNeedsStatusBarAppearanceUpdate()

        self.navigationController?.navigationBar.barStyle = .Default

        navigationItem.title = "Instagram"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(dismiss))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(logout))

        view.addSubview(collectionView)
        
        requestOauthAuthorize()
    }
    
    func requestOauthAuthorize() {
        let oauthswift = OAuth2Swift(
            consumerKey:    clientId,
            consumerSecret: clientSecret,
            authorizeUrl:   authorizeURL,
            responseType:   "token"
        )
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: redirectUrl)!, scope: "basic", state: "INSTAGRAM", success: {
            credential, response, parameters in
            ImageFetcher()
                .onFailure(self.onFailure)
                .onSuccess(self.onSuccess)
                .fetch(credential.oauth_token)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    
    // MARK: create an optionnal internal web view to handle connection
    func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.scheme = redirectUrlScheme
        #if os(OSX)
            controller.view = NSView(frame: NSRect(x:0, y:0, width: 450, height: 500)) // needed if no nib or not loaded from storyboard
            controller.viewDidLoad()
        #endif
        return controller
    }
    
    func get_url_handler() -> OAuthSwiftURLHandlerType {
        // Create a WebViewController with default behaviour from OAuthWebViewController
        let url_handler = createWebViewController()
        #if os(OSX)
            self.addChildViewController(url_handler) // allow WebViewController to use this ViewController as parent to be presented
        #endif
        return url_handler
        
        #if os(OSX)
            // a better way is
            // - to make this ViewController implement OAuthSwiftURLHandlerType and assigned in oauthswift object
            /* return self */
            // - have an instance of WebViewController here (I) or a segue name to launch (S)
            // - in handle(url)
            //    (I) : affect url to WebViewController, and  self.presentViewControllerAsModalWindow(self.webViewController)
            //    (S) : affect url to a temp variable (ex: urlForWebView), then perform segue
            /* performSegueWithIdentifier("oauthwebview", sender:nil) */
            //         then override prepareForSegue() to affect url to destination controller WebViewController
            
        #endif
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    public func present(inViewController: UIViewController, animated: Bool) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.navigationBar.barStyle = UIBarStyle.Default
        inViewController.presentViewController(navigationController, animated: animated, completion: nil)
    }
    
    public func dismiss() {
        onSelectionComplete?(media: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    public func logout() {
        let cookieJar = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        for cookie in cookieJar.cookies! {
            cookieJar.deleteCookie(cookie)
        }
        requestOauthAuthorize()
    }

    private func onSuccess(medias: [IGMedia]) {
        assets = medias
        configureCollectionView()
    }
    
    private func onFailure(error: NSError) {
        let permissionsView = PermissionsView(frame: view.bounds)
        permissionsView.titleLabel.text = "permissions.library.title"
        permissionsView.descriptionLabel.text = "permissions.library.description"
        
        view.addSubview(permissionsView)
    }
    
    private func configureCollectionView() {
        collectionView.registerClass(ImageCell.self, forCellWithReuseIdentifier: ImageCellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func itemAtIndexPath(indexPath: NSIndexPath) -> IGMedia? {
        return assets?[indexPath.row]
    }
}

// MARK: - UICollectionViewDataSource -
extension PhotoLibraryViewController : UICollectionViewDataSource {
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell is ImageCell {
            if let model = itemAtIndexPath(indexPath) {
                (cell as! ImageCell).configureWithModel(model)
            }
        }
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(ImageCellIdentifier, forIndexPath: indexPath)
    }
}

// MARK: - UICollectionViewDelegate -
extension PhotoLibraryViewController : UICollectionViewDelegateFlowLayout {
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let media = itemAtIndexPath(indexPath)
        ImageFetcher().getDataFromUrl(NSURL(string: media!.url!)!) {
            data, response, error in
            media?.imageData = data
            dispatch_async(dispatch_get_main_queue(), {
                self.dismissViewControllerAnimated(true, completion: nil)
                self.onSelectionComplete?(media: media)
            })
        }
    }
}
