
//
//  DUBViewController.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/13/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import DSWaveformImage

//MARK: - Error
enum DubError: Error {
    case invalidJSON
    case noFile
}

/**
 Subclass of UIViewController for capturing the video from a custom video view and export it.
 */
class DUBViewController: UIViewController {

    let recordButton = UIButton()
    var backButton = UIButton()
    var audioFileURL: URL?
    var audioPlayer: AVAudioPlayer?
    var cameraPreview = UIView()
    var captureSession = AVCaptureSession()
    var sessionOutput = AVCapturePhotoOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    func setProgressBar() {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50)
        progressView.progressTintColor = UIColor.magenta
        view.addSubview(progressView)
        UIView.animate(withDuration: 3, animations: { () -> Void in
            progressView.transform = CGAffineTransform(scaleX: 1.0, y: 30.0)
            progressView.setProgress(1.0, animated: true)
        })
    }
    
    //MARK: - Factory Methods
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.lightGray
        
        if let urlString = audioUrlStringFromQuoteJson() {
            
            if let audioURL = URL(string: urlString) {
                downloadAudioFile(url: audioURL)
            }
        }
        
        cameraPreview.frame = view.frame
        view.addSubview(cameraPreview)
        view.bringSubview(toFront: cameraPreview)
        
        setBackButton()
        setUpRecordButton()
        prepareCaptureSession()
        
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized {
            setBackButton()
            setUpRecordButton()
            prepareCaptureSession()
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true {
                    self.setBackButton()
                    self.setUpRecordButton()
                    self.prepareCaptureSession()
                } else {
                    // User Rejected
                }
            })
        }
        
        //Observe the video end
        NotificationCenter.default.addObserver(self, selector: #selector(saveVideoButtonTapped), name: NSNotification.Name(rawValue: DUBSaveDubsmashVideoNotification), object: nil)
    }

    //temporary function for drawing waveform
    fileprivate func setUpWaveFormView(url: URL) {
        let imageView = UIImageView()
        imageView.frame = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 100)
        view.addSubview(imageView)
        view.bringSubview(toFront: imageView)
        let waveformImageDrawer = WaveformImageDrawer()
        
        if let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: url,
                                                                    size: imageView.bounds.size,
                                                                    color: UIColor.blue,
                                                                    style: WaveformStyle.filled,
                                                                    paddingFactor: CGFloat(5.0)) {
            imageView.image = bottomWaveformImage
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }
    
}

//MARK: - Capture, Merge, WaterMArk & Export
extension DUBViewController {
    /**
     Prepare the view for adding captureSession
     */
    fileprivate func prepareCaptureSession() {
        if let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera,AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified) {
            
            for device in deviceDiscoverySession.devices {
                if(device.position == AVCaptureDevicePosition.front){
                    do{
                        let input = try AVCaptureDeviceInput(device: device)
                        if(captureSession.canAddInput(input)) {
                            captureSession.addInput(input)
                            if(captureSession.canAddOutput(sessionOutput)) {
                                captureSession.addOutput(sessionOutput)
                                captureSession.sessionPreset = AVCaptureSessionPreset1280x720
                                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                                
                                movieOutput.movieFragmentInterval = kCMTimeInvalid
                                if let audioFileURL = self.audioFileURL {
                                    let audioAsset = AVURLAsset(url: audioFileURL, options: nil)
                                    let audioDuration = audioAsset.duration as CMTime
                                    let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
                                    movieOutput.maxRecordedDuration = CMTimeMakeWithSeconds(audioDurationSeconds, 30)
                                    previewLayer.frame = cameraPreview.bounds
                                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                                    cameraPreview.layer.addSublayer(previewLayer)
                                    cameraPreview.frame = view.frame
                                }
                            }
                            
                            captureSession.addOutput(movieOutput)
                            captureSession.commitConfiguration()
                            captureSession.startRunning()
                        }
                    } catch {
                        debugPrint("exception!");
                    }
                }
            }
        }
    }
    
    /**
     Merge audio file with recorded video
     
     - Parameter audioUrl:   The audio file url to be merged.
     - Parameter videoUrl: The recorded video file to be merged.
     */
    func mergeAudioTrackWithRecordedVideo(audioUrl: URL, videoUrl: URL) {
        
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let videoAsset = AVURLAsset(url: videoUrl)
        let audioAsset = AVURLAsset(url: audioUrl)
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid))
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid))
        
        let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let audioAssetTrack = audioAsset.tracks(withMediaType: AVMediaTypeAudio)[0]
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: kCMTimeZero)
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), of: audioAssetTrack, at: kCMTimeZero)
            
        } catch let error as NSError {
            
            debugPrint(error.localizedDescription)
        }
        
        mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,mixComposition.duration)
        
        
        var layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableCompositionVideoTrack[0])
        
        //Fix the orientation
        let naturalSize = fixTheOrientation(layerInstruction: &layerInstruction, videoAssetTrack: videoAssetTrack, videoAsset: videoAsset)
        mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
        
        var mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        
        //Add water mark
        addWaterMark(videoComposition: &mutableVideoComposition, instructions: mutableVideoCompositionInstruction, naturalSize: naturalSize)
        
        //Export
        let videoUrl = exportVideoWith(composition: mixComposition, videoComposition: mutableVideoComposition)
        
        //Save the path in Core data
        saveVideoPath(videoUrl: videoUrl)
        
        //Play endlessly
        playVideoInfinitely(videoUrl: videoUrl)
    }
    
    /**
     Fix the video orientation after adding AVMutableVideoCompositionLayerInstruction
     
     - Parameter layerInstruction:   'inout' AVMutableVideoCompositionLayerInstruction
     - Parameter videoAssetTrack: Asset track to get the preferredTransform
     - Parameter videoAsset: video asset
     - Returns: CGSize of the oriented video
     */
    fileprivate func fixTheOrientation(layerInstruction: inout  AVMutableVideoCompositionLayerInstruction, videoAssetTrack: AVAssetTrack, videoAsset: AVURLAsset) -> CGSize {
        
        var isVideoAssetPortrait = false
        let videoTransform = videoAssetTrack.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        
        layerInstruction.setTransform(videoAssetTrack.preferredTransform, at: kCMTimeZero)
        layerInstruction.setOpacity(0.0, at: videoAsset.duration)
        
        var naturalSize: CGSize
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width)
        } else {
            naturalSize = videoAssetTrack.naturalSize
        }
        
        return naturalSize
    }
    
    /**
     Adds water mark on the merged video
     
     - Parameter videoComposition:   'inout' videoComposition for exporting
     - Parameter instructions: AVMutableVideoCompositionInstruction to be added to the composition
     - Parameter naturalSize: CGSize of the oriented video
     */
    fileprivate func addWaterMark(videoComposition: inout AVMutableVideoComposition, instructions: AVMutableVideoCompositionInstruction, naturalSize: CGSize) {
        
        var renderWidth = CGFloat(0.0)
        var renderHeight = CGFloat(0.0)
        renderWidth = naturalSize.width
        renderHeight = naturalSize.height
        
        let waterMarkImage = UIImage(named: "WaterMark")
        let imageLayer = CALayer()
        imageLayer.contents = waterMarkImage?.cgImage
        imageLayer.frame = CGRect(x: 30, y: 30, width: naturalSize.width/2, height: 200)
        imageLayer.opacity = 0.65
        imageLayer.masksToBounds = true
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width , height: naturalSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width , height: naturalSize.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(imageLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.instructions = [instructions]
    }
    
    /**
     Export the merged video with Video composition
     
     - Parameter composition: mixComposition of audio & video
     - Parameter videoComposition: videoComposition for exporting the asset
     - Returns: A valid URL which is exported
     */
    fileprivate func exportVideoWith(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition) -> URL {
        
        //Find video on this URL
        let uuidStr = NSUUID().uuidString
        let documentsDirectoryURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let savePathUrl = URL(fileURLWithPath: documentsDirectoryURL.appending("/\(uuidStr).mp4"))
        
        //Export the video
        let assetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)!
        assetExportSession.videoComposition = videoComposition
        assetExportSession.outputFileType = AVFileTypeQuickTimeMovie
        assetExportSession.outputURL = savePathUrl as URL
        
        assetExportSession.exportAsynchronously { () -> Void in
            switch assetExportSession.status {
                
            case .completed:
                print("Successfully exported")
            case  .failed:
                print("Failed while exporting\(String(describing: assetExportSession.error))")
            case .cancelled:
                print("Cancelled while exporting\(String(describing: assetExportSession.error))")
            default:
                print("default: Completed exporting")
            }
        }
        
        return savePathUrl
    }
    
    /**
     Play the video indefinitely
     
     - Parameter videoUrl: url of a video file to be played indefinitely
     */
    fileprivate func playVideoInfinitely(videoUrl: URL) {
        
        let saveCustomView = DUBSaveCustomView()
        saveCustomView.frame = view.bounds
        view.addSubview(saveCustomView)
        view.bringSubview(toFront: saveCustomView)
        saveCustomView.videoUrl = videoUrl
        sleep(1)
        saveCustomView.playVideoPlayer()
        saveCustomView.setBackButton()
        saveCustomView.setUpSaveButton()
    }
}

//MARK: - Actions
extension DUBViewController {
    
    /**
     Play sound/audio with the provided url
     
     - Parameter url: URL of an audio file
     */
    fileprivate func playSound(with url: URL) {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else { return }
            setUpWaveFormView(url: url)
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    /**
     Action method to save the recorded video
     
     - Parameter notification: Notification sent from customView
     */
    func saveVideoButtonTapped(notification: Notification) {
        
        //Save to camera roll before exporting to documents
        if let videoUrl = notification.object as? URL {
            
            let photos = PHPhotoLibrary.authorizationStatus()
            if photos == .notDetermined {
                PHPhotoLibrary.requestAuthorization({status in
                    if status == .authorized {
                        UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.path, nil, nil, nil)
                        let alertController = UIAlertController(title: "Your Dub saved successfully", message: nil, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        let alertController = UIAlertController(title: "Your Dub couldn't be saved since user decline to give permission to access PhotoLibrary", message: nil, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    /**
     Action method to record a video
     */
    func recordButtonTapped() {
        
        if let audioURL = self.audioFileURL {
            
            //Save the recorded file to documents directory
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            
            movieOutput.startRecording(toOutputFileURL: fileUrl, recordingDelegate: self)
            self.playSound(with: audioURL)
        }
    }
    
    /**
     Persist the video file path in CoreData so that it could be available over app startup
     
     - Parameter videoUrl: URL of the video to be saved
     */
    fileprivate func saveVideoPath(videoUrl: URL) {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let video = DUBVideos(context: context)
            video.fileName = "\(videoUrl.path)"
            appDelegate.saveContext()
        }
    }
}


//MARK: - UI Setup
extension DUBViewController {
    
    fileprivate func setBackButton() {
        if !view.subviews.contains(backButton) {
            backButton = UIButton(frame: CGRect(x: 15, y: 30, width: 60, height: 60))
            let titleStr = "\u{0003C}"
            backButton.setAttributedTitle(NSAttributedString(string: titleStr, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 50), NSForegroundColorAttributeName: UIColor.white]), for: .normal)
            view.addSubview(backButton)
            view.bringSubview(toFront: backButton)
            backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        }
    }
    
    fileprivate func setUpRecordButton() {
        if !view.subviews.contains(recordButton) {
            recordButton.frame = CGRect(x: view.frame.size.width/2 - 50, y: view.frame.size.height - 100, width: 90, height: 90)
            recordButton.setImage(UIImage(named: "Dub"), for: .normal)
            recordButton.backgroundColor = UIColor.clear
            view.addSubview(recordButton)
            view.bringSubview(toFront: recordButton)
            recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        }
    }

}

//MARK: - Download Audio && Parse
extension DUBViewController {
    
    /**
     Get the urlString of the audioFile from JSON
     - Returns: urlStirng of the audioFile
     */
    fileprivate func audioUrlStringFromQuoteJson() -> String? {
        
        var urlString = "" //initialize with empty string
        
        do {
            if let quoteJsonFile = Bundle.main.url(forResource: "quote", withExtension: "json") {
                let data = try Data(contentsOf: quoteJsonFile)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictObject = json as? [String: Any] {
                    //get the url string for audio file.
                    if let audioURL = dictObject["url"] as? String {
                        urlString = audioURL
                    }
                } else if let arrayObject = json as? [Any] {
                    debugPrint("File has an array: \(arrayObject)")
                    
                } else {
                    debugPrint("Invalid JSON")
                    throw DubError.invalidJSON
                }
            } else {
                debugPrint("File does not exists!")
                throw DubError.noFile
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        
        return urlString
    }
    
    /**
     Get the urlString of the audioFile from JSON
     
     - Parameter url: URL of the audioFile to be downloaded
     - Returns: urlStirng of the audioFile
     */
    fileprivate func downloadAudioFile(url: URL) {
        
        //create documents folder url
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        //destination file url
        let destinationURL = documentsDirectoryURL.appendingPathComponent(url.lastPathComponent)
        
        //Check if it exists before downloading
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            
            debugPrint("The audio file already exists at this path!")
            audioFileURL = destinationURL
        }else{
            //File does not exists, so download it asynchronously
            URLSession.shared.downloadTask(with: url, completionHandler: { (urlLocation, response, error) in
                
                guard let location = urlLocation, error == nil else {return}
                
                do {
                    
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    debugPrint("File moved to documents directory")
                    self.audioFileURL = destinationURL
                } catch let error as NSError {
                    
                    debugPrint(error.localizedDescription)
                }
            }).resume()
        }
    }
}

//MARK: - AVCaptureFileOutputRecordingDelegate

extension DUBViewController: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        debugPrint("didFinishRecordingToOutputFileAt")
        
        //Merge audio & video
        mergeAudioTrackWithRecordedVideo(audioUrl: self.audioFileURL!, videoUrl: outputFileURL)
    }
}

//MARK: -
