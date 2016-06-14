//
//  LittlStar.swift
//  
//
//  Created by Gboinyee Tarr on 6/14/16.
//
//


import Foundation
import UIKit


extension LittlstarPlayer : LSPlayerViewDelegate {
    func lsPlayerViewReadyToPlayVideo(lsPlayerView: LSPlayerView!) {
        timeSlider?.maximumValue = Float(lsPlayerView.totalDuration)
        
        lsPlayerView.play(CGFloat(0.0))
        if let spinner = bufferIndicator {
            spinner.stopAnimating()
        }
    }
    
    func lsPlayerViewDidUpdateProgress(lsPlayerView: LSPlayerView!, currentTime: CGFloat, availableTime: CGFloat, totalDuration: CGFloat) {
        if timeSlider!.maximumValue != Float(totalDuration) {
            timeSlider?.maximumValue = Float(totalDuration)
        }
        if isSeeking == false {
            timeSlider!.value = Float(currentTime)
            updateTimeLabel(Int(currentTime))
        }
    }
    
    func lsPlayerViewDidChangeBufferingStatus(lsPlayerView: LSPlayerView!, buffering: Bool) {
        if let spinner = bufferIndicator {
            if buffering {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        }
    }
    
    func lsPlayerViewVideoDidReachEnd(lsPlayerView: LSPlayerView!) {
        if replayDisabled == false {
            lsPlayerView.play(CGFloat(0.0))
        } else {
            playPause()
        }
    }
}


protocol VideoPlayer360Delegate {
    func dismissVideoPlayer360()
}

class LittlstarPlayer : UIViewController{
    
    
    
    var lsPlayerView: LSPlayerView?
    var lsVideoItem: LSVideoItem?
    var lsContentManager: LSContentManager?
    
    var delegate: VideoPlayer360Delegate?
    var videoURL: String?
    
    var topView: UIView?
    var bottomView: UIView?
    var timeSlider: UISlider?
    var playPauseButton: UIButton?
    var replayButton: UIButton?
    var vrModeButton: UIButton?
    var gyroModeButton: UIButton?
    var timeLeftLabel: UILabel?
    var closeButton: UIButton?
    var titleLabel: UILabel?
    var bufferIndicator: UIActivityIndicatorView?
    
    var isSeeking = false
    var replayDisabled = false
    var controlsHidden = false
    
    lazy var isIphone: Bool = UIDevice.currentDevice().userInterfaceIdiom == .Phone
    
    let TOPBAR_HEIGHT = CGFloat(50)
    static let manager = LittlstarPlayer()
    
    
    
    
    
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if isIphone {
            return .LandscapeRight
        } else {
            return .AllButUpsideDown
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return !isIphone
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("Video Disappeared")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        
        lsVideoItem = nil
        lsContentManager = nil
        lsPlayerView = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.stopVRVideo), name: UIApplicationWillResignActiveNotification, object: nil)
        
        lsContentManager = LSContentManager()
        
        lsVideoItem = LSVideoItem()
        
        lsPlayerView = LSPlayerView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
        
        if let pv = lsPlayerView, item = lsVideoItem, url = videoURL {
            
            pv.setDelegate(self)
            view.addSubview(pv)
            //  pv.autoPinEdgesToSuperviewEdges()
            
            item.videoURL = url
            print ("Requested videoPath = \(url)")
            
            constructUI(shouldStartSpinner: true)
            
            //   VideoManager.manager.bypassHardwareMuteSwitch()
            
            playVideo(pv, item:item)
        }
    }
    
    
    func stopVRVideo() {
        
        if let pv = lsPlayerView {
            pv.pause()
            
            
        }
        
        
    }
    
    
    func playVideo(playerView: LSPlayerView, item: LSVideoItem) {
        if let path = NSBundle.mainBundle().pathForResource("com.hearst.khtvnews.license.key.lic", ofType: nil) {
            playerView.initVideoWithVideoItem(lsVideoItem, contentManager: lsContentManager, licenseFileUrl: NSURL(fileURLWithPath: path))
        }
        
    }
    
    
    
    func constructUI(shouldStartSpinner spinner:Bool) {
        // Top bar
        topView = UIView(frame: CGRectMake(0, 0, self.view.bounds.size.width, TOPBAR_HEIGHT))
        topView!.backgroundColor = UIColor(colorLiteralRed:0/255.0, green:0/255.0, blue:0/255.0, alpha:0.5)
        self.view.addSubview(topView!)
        
        // Close button
        closeButton = UIButton(type: UIButtonType.Custom)
        closeButton!.frame = CGRectMake(CGRectGetWidth(topView!.frame)-TOPBAR_HEIGHT, 0, TOPBAR_HEIGHT, TOPBAR_HEIGHT)
        closeButton!.setBackgroundImage(UIImage(named: "360_close"), forState: .Normal)
        closeButton!.addTarget(self, action: #selector(LittlstarPlayer.closeSelected), forControlEvents: .TouchUpInside)
        topView!.addSubview(closeButton!)
        
        // Bottom bar
        bottomView = UIView(frame: CGRectMake(0, self.view.bounds.size.height - TOPBAR_HEIGHT, self.view.bounds.size.width, TOPBAR_HEIGHT))
        bottomView = UIView(frame: CGRectMake(0, self.view.bounds.size.height - TOPBAR_HEIGHT, self.view.bounds.size.width, TOPBAR_HEIGHT))
        bottomView!.backgroundColor = UIColor(colorLiteralRed:0/255.0, green:0/255.0, blue:0/255.0, alpha:0.5)
        self.view.addSubview(bottomView!)
        
        // Gyro mode button
        gyroModeButton = UIButton(type: UIButtonType.Custom)
        gyroModeButton!.frame = CGRectMake(CGRectGetWidth(bottomView!.frame)-TOPBAR_HEIGHT, 0, TOPBAR_HEIGHT, TOPBAR_HEIGHT)
        gyroModeButton!.setImage(UIImage(named: "360_gyro"), forState: .Normal)
        gyroModeButton!.addTarget(self, action: #selector(LittlstarPlayer.changeGyroMode), forControlEvents: .TouchUpInside)
        bottomView!.addSubview(gyroModeButton!)
        
        // VR mode button
        vrModeButton = UIButton(type: UIButtonType.Custom)
        vrModeButton!.frame = CGRectMake(CGRectGetMinX(gyroModeButton!.frame)-TOPBAR_HEIGHT, 0, TOPBAR_HEIGHT, TOPBAR_HEIGHT)
        vrModeButton!.setImage(UIImage(named: "360_vr"), forState: .Normal)
        vrModeButton!.addTarget(self, action: #selector(LittlstarPlayer.changeVRMode), forControlEvents: .TouchUpInside)
        vrModeButton!.alpha = CGFloat(0.5)
        bottomView!.addSubview(vrModeButton!)
        
        // Play button
        playPauseButton = UIButton(type: UIButtonType.Custom)
        playPauseButton!.frame = CGRectMake(0, 0, TOPBAR_HEIGHT, TOPBAR_HEIGHT)
        playPauseButton!.setImage(UIImage(named: "360_pause"), forState: .Normal)
        playPauseButton!.addTarget(self, action: #selector(LittlstarPlayer.playPause), forControlEvents: .TouchUpInside)
        bottomView!.addSubview(playPauseButton!)
        
        // Replay mode button
        replayButton = UIButton(type: UIButtonType.Custom)
        replayButton!.frame = CGRectMake(CGRectGetMinX(vrModeButton!.frame)-TOPBAR_HEIGHT, 0, TOPBAR_HEIGHT, TOPBAR_HEIGHT)
        replayButton!.setImage(UIImage(named: "360_replay"), forState: .Normal)
        replayButton!.addTarget(self, action: #selector(LittlstarPlayer.changeReplayMode), forControlEvents: .TouchUpInside)
        bottomView!.addSubview(replayButton!)
        
        // Time left label
        timeLeftLabel = UILabel(frame:CGRectMake(CGRectGetMinX(replayButton!.frame)-TOPBAR_HEIGHT*2, 0, TOPBAR_HEIGHT*2, TOPBAR_HEIGHT))
        timeLeftLabel!.text = "0:00/0:00"
        //       timeLeftLabel!.textColor = Colors.almostWhiteColor
        timeLeftLabel!.textAlignment = .Center;
        bottomView!.addSubview(timeLeftLabel!)
        
        // Time slider
        let sliderX = CGRectGetMaxX(playPauseButton!.frame);
        let sliderY = CGFloat(0)
        let sliderH = TOPBAR_HEIGHT
        let sliderW = CGRectGetMinX(timeLeftLabel!.frame)-sliderX;
        
        timeSlider = UISlider(frame:CGRectMake(sliderX, sliderY, sliderW, sliderH))
        //        timeSlider!.minimumTrackTintColor = Colors.red
        //        timeSlider!.setThumbImage(drawCircle(15.0, color:Colors.almostWhiteColor), forState:.Normal)
        timeSlider!.addTarget(self, action: #selector(LittlstarPlayer.timeSliderDragExit),     forControlEvents: .TouchUpInside)
        timeSlider!.addTarget(self, action: #selector(LittlstarPlayer.timeSliderDragExit),     forControlEvents: .TouchUpOutside)
        timeSlider!.addTarget(self, action: #selector(LittlstarPlayer.timeSliderDragEnter),    forControlEvents: .TouchDown)
        timeSlider!.addTarget(self, action: #selector(LittlstarPlayer.timeSliderValueChanged), forControlEvents: .ValueChanged)
        timeSlider!.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(LittlstarPlayer.sliderTapped)))
        timeSlider!.minimumValue = 0.0
        timeSlider!.maximumValue = 0.0
        bottomView!.addSubview(timeSlider!)
        
        // Spinner
        bufferIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        bufferIndicator!.center = self.view.center;
        bufferIndicator!.hidesWhenStopped = true
        self.view.addSubview(bufferIndicator!)
        if spinner {
            bufferIndicator!.startAnimating()
        }
        
        // Tap gesture regocnizer
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(LittlstarPlayer.tapDetected))
        view.addGestureRecognizer(tapGr)
    }
    
    func drawCircle(diameter: CGFloat, color: UIColor) -> UIImage {
        var circle = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), false, CGFloat(0))
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        
        let rect = CGRectMake(0, 0, diameter, diameter)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillEllipseInRect(ctx, rect)
        
        CGContextRestoreGState(ctx)
        circle = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return circle
    }
    
    func showHideControlBars(hide: Bool) {
        if hide == controlsHidden { return }
        
        if let top = topView, bottom = bottomView {
            var topFrame = top.frame
            var bottomFrame = bottom.frame
            
            if hide {
                topFrame.origin.y = -topFrame.size.height
                bottomFrame.origin.y = view.bounds.size.height
            } else {
                topFrame.origin.y = 0
                bottomFrame.origin.y = view.bounds.size.height - bottomFrame.size.height
            }
            
            controlsHidden = hide
            UIView.animateWithDuration(0.3) {
                top.frame = topFrame
                bottom.frame = bottomFrame
            }
        }
    }
    
    func updateTimeLabel(totalSeconds: Int) {
        let seconds = totalSeconds % 60;
        let minutes = (totalSeconds / 60) % 60;
        let durationSeconds = Int(timeSlider!.maximumValue) % 60
        let durationMinutes = Int(timeSlider!.maximumValue/60) % 60;
        
        timeLeftLabel!.text = NSString.localizedStringWithFormat("%d:%02d/%d:%02d", minutes, seconds, durationMinutes, durationSeconds) as String
    }
    
    //MARK: - UI Control Handlers
    func tapDetected(gr: UITapGestureRecognizer) {
        showHideControlBars(!controlsHidden)
    }
    
    func playPause() {
        if let pv = lsPlayerView {
            if pv.isPaused() {
                pv.play()
                playPauseButton!.setImage(UIImage(named: "360_pause"), forState: .Normal)
            } else {
                pv.pause()
                playPauseButton!.setImage(UIImage(named: "360_play"), forState: .Normal)
            }
        }
    }
    
    func closeSelected() {
        playPause()
        if let pv = lsPlayerView {
            pv.removeFromSuperview()
        }
        delegate?.dismissVideoPlayer360()
        
    }
    
    func changeGyroMode(button: UIButton) {
        if let pv = lsPlayerView {
            pv.sensorsDisabled = !pv.sensorsDisabled;
            var alpha = CGFloat(1.0)
            if (pv.sensorsDisabled) {
                alpha = CGFloat(0.5)
            }
            button.alpha = alpha;
        }
    }
    
    func changeVRMode(button: UIButton) {
        if let pv = lsPlayerView {
            pv.vrModeEnabled = !pv.vrModeEnabled;
            var alpha = CGFloat(1.0)
            if !pv.vrModeEnabled {
                alpha = CGFloat(0.5)
            } else {
                showHideControlBars(true)
            }
            button.alpha = alpha;
        }
    }
    
    func changeReplayMode(button: UIButton) {
        replayDisabled = !replayDisabled;
        var alpha = CGFloat(1.0)
        if replayDisabled {
            alpha = CGFloat(0.5)
        }
        button.alpha = alpha;
    }
    
    func timeSliderDragExit(slider: UISlider) {
        if let pv = lsPlayerView {
            pv.seekTo(CGFloat(slider.value))
        }
        isSeeking = false
        updateTimeLabel(Int(slider.value))
    }
    
    func timeSliderDragEnter() {
        isSeeking = true
    }
    
    func timeSliderValueChanged(slider: UISlider) {
        updateTimeLabel(Int(slider.value))
    }
    
    func sliderTapped(gesture: UIGestureRecognizer) {
        if let sliderView = gesture.view as? UISlider {
            isSeeking = true
            let pt = gesture.locationInView(sliderView)
            let percent = pt.x / sliderView.bounds.size.width
            let delta = Float(percent) * (sliderView.maximumValue - sliderView.minimumValue)
            let value = sliderView.minimumValue + delta
            sliderView.setValue(value, animated: true)
            if let pv = lsPlayerView {
                pv.seekTo(CGFloat(value))
            }
            isSeeking = false
            updateTimeLabel(Int(value))
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.topView?.removeFromSuperview()
            self.bottomView?.removeFromSuperview()
            self.bufferIndicator?.removeFromSuperview()
            if let pv = self.lsPlayerView {
                pv.frame = self.view.frame
            }
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                self.constructUI(shouldStartSpinner: false)
        })
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
}
