//
//  WebView.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import OAuthSwift

#if os(iOS)
    import UIKit
    typealias WebView = UIWebView // WKWebView
#elseif os(OSX)
    import AppKit
    import WebKit
    typealias WebView = WKWebView
#endif

class WebViewController: OAuthWebViewController {

    var targetURL : NSURL = NSURL()
    let webView : WebView = WebView()
    
    var scheme: String!

    let myProgressView: UIProgressView = UIProgressView(progressViewStyle: .Bar)
    var theBool: Bool = false
    var myTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()

        #if os(iOS)
            
            let navbar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
            self.view.addSubview(navbar)
            navbar.barStyle = .Default

            let navitem: UINavigationItem = UINavigationItem(title: "Instagram Login")
            navitem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(dismiss))
            navbar.items = [navitem]
            
            self.webView.frame = self.view.frame
            self.webView.frame.origin.y = 60
            self.webView.scalesPageToFit = true
            self.webView.delegate = self
            self.view.addSubview(self.webView)
            self.myProgressView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 5)
            self.view.addSubview(self.myProgressView)
            loadAddressURL()
        #elseif os(OSX)
            
            self.webView.frame = self.view.bounds
            self.webView.navigationDelegate = self
            self.webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.webView)
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
        #endif
        
    }

    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func handle(url: NSURL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }

    func loadAddressURL() {
        let req = NSURLRequest(URL: targetURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData,
                               timeoutInterval: 10.0)
        self.webView.loadRequest(req)
    }
    
    func funcToCallWhenStartLoadingYourWebview() {
        self.myProgressView.setProgress(0.0, animated: true)
        self.theBool = false
        self.myTimer = NSTimer.scheduledTimerWithTimeInterval(0.01667, target: self, selector: #selector(WebViewController.timerCallback), userInfo: nil, repeats: true)
    }
    
    func funcToCallCalledWhenUIWebViewFinishesLoading() {
        self.theBool = true
    }
    
    func timerCallback() {
        if self.theBool {
            if self.myProgressView.progress >= 1 {
                self.myProgressView.hidden = true
                self.myTimer.invalidate()
            } else {
                self.myProgressView.setProgress(self.myProgressView.progress + 0.1, animated: true)
            }
        } else {
            self.myProgressView.setProgress(self.myProgressView.progress + 0.005, animated: true)
            if self.myProgressView.progress >= 0.95 {
                self.myProgressView.setProgress(0.95, animated: true)
            }
        }
    }
}

// MARK: delegate
#if os(iOS)
    extension WebViewController: UIWebViewDelegate {
        func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
            if let url = request.URL where (url.scheme == scheme){
                self.dismissWebViewController()
            }
            return true
        }
        
        func webViewDidStartLoad(webView: UIWebView) {
            funcToCallWhenStartLoadingYourWebview()
        }
        func webViewDidFinishLoad(webView: UIWebView) {
            funcToCallCalledWhenUIWebViewFinishesLoading()
        }
    }

#elseif os(OSX)
    extension WebViewController: WKNavigationDelegate {
        
        func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {

            // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
            if let url = navigationAction.request.URL where url.scheme == scheme {
                AppDelegate.sharedInstance.applicationHandleOpenURL(url)
                decisionHandler(.Cancel)
                
                self.dismissWebViewController()
                return
            }
            
            decisionHandler(.Allow)
        }
        
        /* override func  webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if request.URL?.scheme == "oauth-swift" {
        self.dismissWebViewController()
        }
        
        } */
    }
#endif
