//
//  ViewController.swift
//  Instagram Picker Demo
//
//  Created by Niltava Labs on 6/7/16.
//  Copyright © 2016 Niltava Labs. All rights reserved.
//

import UIKit
import InstagramPicker

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pick(sender: UIButton) {
        let controller: PhotoLibraryViewController = PhotoLibraryViewController(clientId: "4edade7dc6e3423ea25639267d13d5f2", clientSecret: "aa4dc2af8bbe45edad1e69107732f541", redirectUrl: "oauth-swift://oauth-callback/instagram", redirectUrlScheme: "oauth-swift")
        controller.onSelectionComplete = selectionComplete
        controller.present(self, animated: true)
    }

    func selectionComplete(media: IGMedia?) {
        print("media url = \(media?.url)")
    }
    
}

