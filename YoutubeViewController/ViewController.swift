//
//  ViewController.swift
//  YoutubeViewController
//
//  Created by YehYungCheng on 2016/6/12.
//  Copyright © 2016年 YehYungCheng. All rights reserved.
//

import UIKit

class ViewController: UIViewController, YoutubeViewControllerDelegate {

    var windows2: UIWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    @IBAction func onClick() {
        let youtube = YoutubeViewController()
        youtube.delegate = self
        windows2 = UIWindow(frame: self.view.bounds)
        windows2?.rootViewController = youtube
        windows2?.makeKeyAndVisible()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            youtube.play("C7wRb9adQUc")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - YoutubeViewControllerDelegate
    func youtubeDidClose(youtubeController: YoutubeViewController) {
        windows2?.hidden = true
        windows2 = nil
    }
}

