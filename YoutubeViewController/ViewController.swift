//
//  ViewController.swift
//  YoutubeViewController
//
//  Created by YehYungCheng on 2016/6/12.
//  Copyright © 2016年 YehYungCheng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.onClick()
        }
    }
    
    @IBAction func onClick() {
        let youtube = YoutubeViewController()
        self.presentViewController(youtube, animated: true) {
            youtube.play("C7wRb9adQUc")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

