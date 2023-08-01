//
//  ViewController.swift
//  Radio1
//
//  Created by ismmajl on 09/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import UIKit
import MediaPlayer
import MarqueeLabel
import Firebase

enum PlayerState {
    case play
    case pause
    case waiting
}

class ViewController: UIViewController {
    
    //MARK: - OUTLETS
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segmentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var segmentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var employeesButton: UIButton!
    @IBOutlet weak var programButton: UIButton!
    
    //MARK: - VARIABLES
    var player: AVPlayer! = AVPlayer.init(url: URL(string: Preferences.streamUrl)!)
    var reachability: Reachability!
    
    
    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNowPlayingInfo()
        commonInit()
        setupReachability()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationChangedState), name: NSNotification.Name(rawValue: "ApplicationStatusChanged"), object: nil)

        changePlayer(state: .play)
        loadStreamUrlFromFirebase()
    }
    
    @objc func applicationChangedState(notitication: Notification) {
        reloadItems()
    }
    
    //loading stream url from firebase and store to preferences
    func loadStreamUrlFromFirebase() {
        let db = Firestore.firestore()
        let docRef = db.collection("settings").document("main")
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let strId = document.get("stream_id") as? String {
                    Preferences.streamUrl = strId
                    DispatchQueue.main.async {
                        self.changePlayer(state: .play)
                    }
                }
            }
        }
    }
    
    func reloadItems() {
        if let show = Program.getShowWhilePlaying() {
            titleLabel.text = show.title
        }else {
            titleLabel.text = "Radio ONE"
        }
        setNowPlayingInfo()
    }
    
    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionAlert), name: AVAudioSession.interruptionNotification, object: nil)
        reloadItems()
        scrollView.delegate = self
        
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = UIColor.white
            slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.44)
        }
        if let button = volumeView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.tintColor = UIColor.white
        }
        titleLabel.type = .leftRight
    }
    
    @objc func interruptionAlert(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            changePlayer(state: .pause)
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    changePlayer(state: .play)
                } else {
                    changePlayer(state: .pause)
                }
            }
        }
    }
    
    func setupReachability() {
        do {
            reachability = try Reachability()
            
            reachability.whenReachable = { [weak self] reachability in
                print("Reachable")
                
                guard let `self` = self else { return }
                
                if self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    self.changePlayer(state: .play)
                }
            }
            reachability.whenUnreachable = { _ in
                print("Not reachable")
            }
            
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func setNowPlayingInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        var title = "Radio ONE"
        if let show = Program.getShowWhilePlaying() {
            title = show.title
        }else {
            title = "Radio ONE"
        }
        let album = "Radio Një"
        let image = UIImage(named: "AppIcon")!
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    override func remoteControlReceived(with event: UIEvent?) {
        if let e = event , e.type == .remoteControl {
            if  e.subtype == UIEvent.EventSubtype.remoteControlPause {
                changePlayer(state: .pause)
            }else if(e.subtype == .remoteControlPlay){
                changePlayer(state: .play)
            }else if(e.subtype == .remoteControlTogglePlayPause){
                let newState: PlayerState = player.timeControlStatus == AVPlayer.TimeControlStatus.paused ? PlayerState.play : PlayerState.pause
                changePlayer(state: newState)
            }
        }
    }
    
    func changePlayer(state: PlayerState)  {
        switch state {
        case .play:
            self.player = AVPlayer.init(url: URL(string: Preferences.streamUrl)!)
            self.player.play()
            playButton.setImage(UIImage(named: "pause"), for: .normal)
            
        case .pause:
            self.player.pause()
            playButton.setImage(UIImage(named: "play"), for: .normal)
            
        case .waiting:
            playButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    
    //MARK: - OTHER FUNCTIONS
    func displayShareSheet(sender: UIButton) {
        let objectsToShare = [Constants.shareText] as [Any]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.mail, UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.postToTwitter, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.mail]
        if let wPPC = activityVC.popoverPresentationController {
            wPPC.sourceRect = sender.frame
            wPPC.sourceView = UIView(frame: sender.frame)
            wPPC.permittedArrowDirections = []
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    //MARK: - ACTIONS
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if player.timeControlStatus == .playing || player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            changePlayer(state: .pause)
        } else  {
            changePlayer(state: .play)
        }
    }
    @IBAction func aboutButtonPressed(_ sender: UIButton) {
        goToIndex(index: 2)
    }
    @IBAction func employeesButtonPressed(_ sender: UIButton) {
        goToIndex(index: 1)
    }
    @IBAction func programButtonPressed(_ sender: UIButton) {
        goToIndex(index: 0)
    }
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        displayShareSheet(sender: sender)
    }
}

//MARK: - SCROLLVIEW DELEGATES
extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        guard offset >= 0 && offset < (scrollView.contentSize.width - scrollView.frame.width) else { return }
        animateButtons(page: scrollView.currentPage)
    }
    func animateButtons(page: Int) {
        UIView.animate(withDuration: 0.2) {
            self.programButton.setTitleColor(page == 0 ? UIColor.white : UIColor.white.withAlphaComponent(0.44), for: .normal)
            self.employeesButton.setTitleColor(page == 1 ? UIColor.white : UIColor.white.withAlphaComponent(0.44), for: .normal)
            self.aboutButton.setTitleColor(page == 2 ? UIColor.white : UIColor.white.withAlphaComponent(0.44), for: .normal)
            
            switch page {
            case 0:
                self.segmentLeadingConstraint.constant = 0
                self.segmentWidthConstraint.constant = self.programButton.frame.width
            case 1:
                self.segmentLeadingConstraint.constant = self.programButton.frame.width + 24
                self.segmentWidthConstraint.constant = self.employeesButton.frame.width
            case 2:
                self.segmentLeadingConstraint.constant = self.programButton.frame.width + self.employeesButton.frame.width + 48
                self.segmentWidthConstraint.constant = self.aboutButton.frame.width
            default:
                break
            }
            
            self.view.layoutIfNeeded()
        }
    }
    func goToIndex(index: Int, animated: Bool = true) {
        print("current: \(scrollView.currentPage) goTo: \(index)")
        let newIndexPath = IndexPath(item: index, section: 0)
        scrollView.setContentOffset(CGPoint(x: CGFloat(newIndexPath.item) * scrollView.frame.width, y: 0), animated: true)
    }
}
