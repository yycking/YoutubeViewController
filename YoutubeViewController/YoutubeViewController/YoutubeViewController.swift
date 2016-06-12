//
//  YoutubeViewController.swift
//  YoutubeViewController
//
//  Created by YehYungCheng on 2016/5/29.
//  Copyright © 2016年 YehYungCheng. All rights reserved.
//

import UIKit
import WebKit

let YOUTUBE_HOST = "www.youtube.com"

class YoutubeViewController: UIViewController, WKScriptMessageHandler{
    @IBOutlet weak var youtubeView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    var webView: WKWebView!
    @IBOutlet weak var bottomBar: UIVisualEffectView!
    @IBOutlet weak var topBar: UIVisualEffectView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var remainderTime: UILabel!
    
    var needUpdate = true
    var hideTimer: NSTimer?
    var playTimer: NSTimer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view
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
    
    func createWebView() {
        if let view = webView {
            view.removeFromSuperview()
        }
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.requiresUserActionForMediaPlayback = false
        config.userContentController.addScriptMessageHandler(self, name: "youtubeApp")
        
        webView = WKWebView(frame: youtubeView.frame, configuration: config)
        webView.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
        webView.scrollView.scrollEnabled = false
        webView.scrollView.bounces = false
        
        youtubeView.addSubview(webView)
    }
    
    func play(youtubeID: String) {
        self.createWebView()
        
        let path = NSBundle.mainBundle().URLForResource(
            "Youtube", withExtension:"html")
        let embedHTMLTemplate = try! String(
            contentsOfURL: path!, encoding: NSUTF8StringEncoding)
        let embedHTML = NSString(
            format: embedHTMLTemplate, youtubeID)
        
        webView.loadHTMLString(embedHTML as String, baseURL: NSURL(string: "https://\(YOUTUBE_HOST)"))
    }
    
    @IBAction func close() {
        webView.evaluateJavaScript("player.stopVideo();", completionHandler: nil)
        self.dismissViewControllerAnimated(true) {
        }
        if let timer = playTimer {
            timer.invalidate()
        }
    }
    
    @IBAction func changeSecond() {
        if let timer = hideTimer {
            timer.invalidate()
        }
        if needUpdate == false {
            let command = String(format: "player.seekTo(%f, true);", timeSlider.value)
            webView.evaluateJavaScript(command, completionHandler: nil)
        }
        self.updateBottomBar()
    }
    
    @IBAction func startUpdate() {
        needUpdate = true
        webView.evaluateJavaScript("player.playVideo();", completionHandler: nil)
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
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let dict = message.body as? [String:String],
                method = dict["method"]{
            switch method {
            case "ready":
                self.playerViewDidBecomeReady()
                break
                
            case "ended":
                self.close()
                break
                
            case "playing":
                self.hideBar()
                break
                
            case "paused":
                let height = self.view.frame.height
                UIView.animateWithDuration(0.5, animations: {
                    self.topBar.center.y = 22
                    self.bottomBar.center.y = height - 22
                })
                break
                
            default:
                break
            }
        }
    }

    func playerViewDidBecomeReady() {
        webView.evaluateJavaScript("player.getDuration();") {[weak self] (any,error) -> Void in
            if let timeDuration = any as? NSNumber, weakSelf = self {
                weakSelf.timeSlider.maximumValue = timeDuration.floatValue
            }
        }
        playTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: #selector(YoutubeViewController.didPlayTime), userInfo: nil, repeats: true)
    }
    
    func didPlayTime() {
        if needUpdate {
            webView.evaluateJavaScript("player.getCurrentTime();") {[weak self] (any,error) -> Void in
                if let playTime = any as? NSNumber, weakSelf = self {
                    weakSelf.timeSlider.value = playTime.floatValue
                }
            }
        }
        self.updateBottomBar()
    }
}
