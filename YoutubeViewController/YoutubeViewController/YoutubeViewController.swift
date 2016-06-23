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
    @IBOutlet weak var touchView: UIView!
    @IBOutlet weak var youtubeView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var seekingBar: UIVisualEffectView!
    @IBOutlet weak var topBar: UIVisualEffectView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var remainderTime: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var zoomButton: UIButton!
    
    var webView: WKWebView!
    
    var isSeeking = false
    var isFullScreen = false
    var isZoomIn = false
    var isPlaying = false
    var enterFullScreenTimer: NSTimer?
    var seekUpdater: NSTimer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if isFullScreen {
            autoEnterFullScreen()
        }
        
        if webView != nil {
            NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: #selector(zoomPlayer as (Void)->Void), userInfo: nil, repeats: false)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
        config.selectionGranularity = .Character
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
    
    @IBAction func pause() {
        if isPlaying {
            webView.evaluateJavaScript("player.pauseVideo();", completionHandler: nil)
        } else {
            webView.evaluateJavaScript("player.playVideo();", completionHandler: nil)
        }
        autoEnterFullScreen()
    }
    
    @IBAction func close() {
        webView.evaluateJavaScript("player.stopVideo();", completionHandler: nil)
        webView.loadHTMLString("", baseURL: nil)
        webView.configuration.userContentController.removeScriptMessageHandlerForName("youtubeApp")
        webView.stopLoading()
        self.dismissViewControllerAnimated(true) {
        }
        if let timer = seekUpdater {
            timer.invalidate()
        }
    }
    
    func zoomPlayer() {
        var bounds = youtubeView.bounds
        
        if isZoomIn {
            if bounds.height < bounds.width {
                bounds.size.height = bounds.width
            } else {
                bounds.size.width = bounds.height
            }
        }
        
        webView.bounds = bounds
    }
    
    @IBAction func zoomPlayer(sender: AnyObject) {
        
        isZoomIn = !isZoomIn
        zoomPlayer()
        autoEnterFullScreen()
    }
    
    @IBAction func changeSecond() {
        if let timer = enterFullScreenTimer {
            timer.invalidate()
        }
        if isSeeking {
            let command = String(format: "player.seekTo(%f, true);", timeSlider.value)
            webView.evaluateJavaScript(command, completionHandler: nil)
        }
        self.updateSeekingBar()
        autoEnterFullScreen()
    }
    
    @IBAction func stopSeeking() {
        isSeeking = false
        seekUpdater?.fire()
    }
    
    @IBAction func startSeeking() {
        isSeeking = true
        seekUpdater?.invalidate()
    }
    
    func updateSeekingBar() {
        let current = Int(timeSlider.value)
        currentTime.text = String(format: "%02d:%02d", current/60, current%60)
        
        let remainder = Int(timeSlider.maximumValue - timeSlider.value)
        remainderTime.text = String(format: "-%02d:%02d", remainder/60, remainder%60)
    }
    
    @IBAction func switchMode() {
        if isFullScreen {
            toInlineMode()
            
        } else {
            toFullScreen()
        }
        autoEnterFullScreen()
    }
    
    func toInlineMode() {
        let height = self.view.frame.height
        UIView.animateWithDuration(0.1, animations: {
            self.topBar.center.y = 22
            self.seekingBar.center.y = height - 22
        })
        
        isFullScreen = false
    }
    
    func toFullScreen() {
        let height = self.view.frame.height
        
        UIView.animateWithDuration(0.1, animations: {
            self.topBar.center.y = -44
            self.seekingBar.center.y = height + 44
        })
        
        isFullScreen = true
    }
    
    func autoEnterFullScreen() {
        if let timer = enterFullScreenTimer {
            timer.invalidate()
        }
        enterFullScreenTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(YoutubeViewController.toFullScreen), userInfo: nil, repeats: false)
    }
    
    // MARK: - Web Delegate
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let dict = message.body as? [String:String],
                method = dict["method"]{
            switch method {
            case "ready":
                self.playerViewDidBecomeReady()
                break
                
            case "playing":
                isPlaying = true
                playButton.setTitle("▷", forState: .Normal)
                break
            
            case "paused":
                isPlaying = false
                playButton.setTitle("▶︎", forState: .Normal)
                break
                
            case "ended":
                self.close()
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
        
        webView.evaluateJavaScript("player.getVideoData().title;") {[weak self] (any,error) -> Void in
            if let title = any as? String, weakSelf = self {
                weakSelf.titleLabel.text = title
            }
        }
        
        seekUpdater = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: #selector(YoutubeViewController.didPlayTime), userInfo: nil, repeats: true)
        autoEnterFullScreen()
    }
    
    func didPlayTime() {
        if isFullScreen == false {
            webView.evaluateJavaScript("player.getCurrentTime();") {[weak self] (any,error) -> Void in
                if let playTime = any as? NSNumber, weakSelf = self {
                    weakSelf.timeSlider.value = playTime.floatValue
                }
            }
            self.updateSeekingBar()
        }
    }
}
