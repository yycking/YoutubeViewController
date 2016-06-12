//
//  YoutubeViewController.swift
//  YoutubeViewController
//
//  Created by YehYungCheng on 2016/5/29.
//  Copyright © 2016年 YehYungCheng. All rights reserved.
//

import UIKit

let YOUTUBE_HOST = "www.youtube.com"

class YoutubeViewController: UIViewController, UIWebViewDelegate{
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var bottomBar: UIVisualEffectView!
    @IBOutlet weak var topBar: UIVisualEffectView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var remainderTime: UILabel!
    
    var needUpdate = true
    var hideTimer: NSTimer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
        webView.scrollView.scrollEnabled = false
        webView.scrollView.bounces = false
        webView.delegate = self
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if needUpdate {
            if let timer = hideTimer {
                timer.invalidate()
            }
            hideTimer = NSTimer.scheduledTimerWithTimeInterval(
                3.0,
                target: self,
                selector: #selector(YoutubeViewController.hideBar),
                userInfo: nil,
                repeats: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func play(youtubeID: String) {
        let path = NSBundle.mainBundle().URLForResource(
            "Youtube", withExtension:"html")
        let embedHTMLTemplate = try! String(
            contentsOfURL: path!, encoding: NSUTF8StringEncoding)
        let embedHTML = NSString(
            format: embedHTMLTemplate, youtubeID)
        
        webView.loadHTMLString(embedHTML as String, baseURL: NSURL(string: "https://\(YOUTUBE_HOST)"))
    }
    
    @IBAction func close() {
        webView.stringByEvaluatingJavaScriptFromString("player.stopVideo();")
        self.dismissViewControllerAnimated(true) {
        }
    }
    
    @IBAction func changeSecond() {
        if let timer = hideTimer {
            timer.invalidate()
        }
        if needUpdate == false {
            let command = String(format: "player.seekTo(%f, true);", timeSlider.value)
            webView.stringByEvaluatingJavaScriptFromString(command)
        }
        self.updateBottomBar()
    }
    
    @IBAction func startUpdate() {
        needUpdate = true
        webView.stringByEvaluatingJavaScriptFromString("player.playVideo();")
    }
    
    @IBAction func stopUpdate() {
        needUpdate = false
    }
    
    func updateBottomBar() {
        if topBar.center.y > 0 {
            let current = Int(timeSlider.value)
            currentTime.text = String(format: "%02d:%02d", current/60, current%60)
            
            let remainder = Int(timeSlider.maximumValue - timeSlider.value)
            remainderTime.text = String(format: "-%02d:%02d", remainder/60, remainder%60)
        }
    }
    
    func hideBar() {
        let height = self.view.frame.height
        
        UIView.animateWithDuration(0.5, animations: {
            self.topBar.center.y = -44
            self.bottomBar.center.y = height + 44
        })
    }
    
    // MARK: - Web Delegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            let scheme = url.scheme
            let host = url.host
            let height = self.view.frame.height
            
            switch scheme {
            case "ready":
                self.playerViewDidBecomeReady()
                return false
                
            case "playtime":
                self.didPlayTime(host!)
                return false
                
            case "ended":
                self.close()
                return false
                
            case "playing":
                self.hideBar()
                return false
                
            case "paused":
                UIView.animateWithDuration(0.5, animations: {
                    self.topBar.center.y = 22
                    self.bottomBar.center.y = height - 22
                })
                return false
                
            default:
                break
            }
        }
        return true
    }

    func playerViewDidBecomeReady() {
        if let result = webView.stringByEvaluatingJavaScriptFromString("player.getDuration();") {
            let timeDuration = (result as NSString).floatValue
            timeSlider.maximumValue = Float(timeDuration)
        }
    }
    
    func didPlayTime(playTime: NSString) {
        if needUpdate {
            timeSlider.value = playTime.floatValue
        }
        self.updateBottomBar()
    }
}
