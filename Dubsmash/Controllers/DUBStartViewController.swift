//
//  DUBStartViewController.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/15/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

/**
 Subclass of AVPlayerViewController which plays a video file endlessly which was recorded and merged with an audio(my DUB)
 */
class DUBStartViewController: AVPlayerViewController {
    
    var videoUrl: URL?
    
    //MARK: - Factory methods
    override func loadView() {
        super.loadView()

        setBackButton()
        setRedubButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        //Video should playback in an endless loop until some actions taken
        if let player = player {
            //Add the notification observer to play the video endlessly once it ends.
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object:
                player.currentItem, queue: nil, using: { (_) in
                    DispatchQueue.main.async {
                        player.seek(to: kCMTimeZero)
                        player.play()
                    }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playVideo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        player?.rate = 0.0
        player = nil
    }

    
    
    
}

//MARK: - UI Setup
extension DUBStartViewController {
    
    fileprivate func setBackButton() {
        let backButton = UIButton(frame: CGRect(x: 0, y: 30, width: 60, height: 60))
        let titleStr = "\u{0003C}"
        backButton.setAttributedTitle(NSAttributedString.init(string: titleStr, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 50), NSForegroundColorAttributeName: UIColor.white]), for: .normal)
        view.addSubview(backButton)
        view.bringSubview(toFront: backButton)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    fileprivate func setRedubButton() {
        let reDubButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 130, y: UIScreen.main.bounds.height - 60, width: 100, height: 50))
        reDubButton.setAttributedTitle(NSAttributedString(string: "Redub", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor.white]), for: .normal)
        reDubButton.backgroundColor = UIColor.gray
        reDubButton.layer.cornerRadius = 10
        view.addSubview(reDubButton)
        view.bringSubview(toFront: reDubButton)
        reDubButton.addTarget(self, action: #selector(reDubButtonTapped), for: .touchUpInside)
    }
}

//MARK: - Actions
extension DUBStartViewController {
    
    func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func reDubButtonTapped() {
        let dubVC = DUBViewController()
        navigationController?.pushViewController(dubVC, animated: true)
    }
    
    /**
     Play the video file provided to this VC else play the standard video
     */
    func playVideo() {
        
        if let videoUrl = self.videoUrl {
            player = AVPlayer(url: videoUrl)
        }else if let videoUrl = Bundle.main.url(forResource: "Clip", withExtension: "mp4") {
            player = AVPlayer(url: videoUrl)
        } else {
            debugPrint("Could not load video file")
        }
        
        showsPlaybackControls = false
        
        DispatchQueue.main.async {
            self.player?.play()
        }
    }
}
