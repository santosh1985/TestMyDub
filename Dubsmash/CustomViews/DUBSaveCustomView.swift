//
//  DUBSaveCustomView.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/16/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

let DUBSaveDubsmashVideoNotification = "DUBSaveDubsmashVideoNotification"

class DUBSaveCustomView: UIView {

    //MARK: - vars
    var videoUrl: URL?
    var player: AVPlayer?
    
    //MARK: - inits
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

//MARK: - UI Setup
extension DUBSaveCustomView {
    
    func setUpSaveButton() {
        let saveButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 80, y: 30, width: 50, height: 50))
        saveButton.setImage(UIImage(named: "DownloadIcon"), for: .normal)
        addSubview(saveButton)
        bringSubview(toFront: saveButton)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    func setBackButton() {
        let backButton = UIButton(frame: CGRect(x: 0, y: 30, width: 60, height: 60))
        let titleStr = "\u{0003C}"
        backButton.setAttributedTitle(NSAttributedString.init(string: titleStr, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 50), NSForegroundColorAttributeName: UIColor.white]), for: .normal)
        addSubview(backButton)
        bringSubview(toFront: backButton)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
}

//MARK: - Actions
extension DUBSaveCustomView {
    
    /**
     Play the video player with provided video file url and also add the notification observer to play the video endlessly
     */
    func playVideoPlayer() {
        if let videoUrl = self.videoUrl {
            player = AVPlayer(url: videoUrl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = bounds
            layer.addSublayer(playerLayer)
            player?.play()
        }
        
        //Video should playback in an endless loop until some actions taken
        if let player = player {
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object:
                player.currentItem, queue: nil, using: { (_) in
                    DispatchQueue.main.async {
                        player.seek(to: kCMTimeZero)
                        player.play()
                    }
            })
        }
    }
    
    func backButtonTapped() {
        player?.pause()
        player?.rate = 0.0
        player = nil
        removeFromSuperview()
    }
    
    /**
     Post the notification to handle the video file saving to Camera Roll
     */
    func saveButtonTapped() {
        if let videoUrl = self.videoUrl {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: DUBSaveDubsmashVideoNotification), object: videoUrl as Any)
            player?.pause()
            player?.rate = 0.0
            player = nil
        }
    }
}
