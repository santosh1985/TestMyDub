//
//  DUBTableViewController.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/16/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit


let cellReuseIdentifier = "DubCell"
let viewTitle = "Old Dubs"

/**
 Subclass of UITableViewController, to list all the old DUBs
 */
class DUBTableViewController: UITableViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var videos: [DUBVideos] = []
    var saveCustomView: DUBSaveCustomView?
    
    //MARK: - Factory methods
    override func loadView() {
        super.loadView()
        
        title = viewTitle
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveCustomView?.removeFromSuperview()
        saveCustomView?.player?.pause()
        saveCustomView?.player?.rate = 0.0
        saveCustomView?.player = nil
        
        navigationController?.isNavigationBarHidden = true
    }

}

//MARK: - Privates
extension DUBTableViewController {
    
    /**
     Fetch the saved videos from CoreData
     */
    fileprivate func getData() {
        do {
            videos = try context.fetch(DUBVideos.fetchRequest()) as! [DUBVideos]
            if videos.count > 0 {
                self.tableView.reloadData()
            }
        } catch {
            print("Fetching Failed")
        }
    }
    
    /**
     Play the video endlessly
     
     - Parameter videoUrl: URL of the video file
     */
    fileprivate func playVideoInfinitely(_ videoUrl: URL) {
        
        saveCustomView = DUBSaveCustomView()
        saveCustomView?.frame = view.bounds
        view.addSubview(saveCustomView!)
        view.bringSubview(toFront: saveCustomView!)
        saveCustomView?.videoUrl = videoUrl
        sleep(1)
        saveCustomView?.playVideoPlayer()
        saveCustomView?.setBackButton()
        saveCustomView?.setUpSaveButton()
    }
}

//MARK: - DataSource
extension DUBTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return videos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        configureCell(&cell, indexPath: indexPath)
        
        return cell
    }
    /**
     Configure the UITableViewCell here so that keep the datasource method clean.
     
     - Parameter cell: 'inout' cell to be configured
     - Parameter indexPath: IndexPath of the cell to be configured
     */
    fileprivate func configureCell(_ cell: inout UITableViewCell, indexPath: IndexPath) {
        
        let video = videos[indexPath.row]
        
        if let _ = video.fileName {
            cell.textLabel?.text = "Video ==> \(indexPath.row)"
        }
    }
}

//MARK: - Delegates
extension DUBTableViewController {
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80
//    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoFile = videos[indexPath.row]
        if let fileName = videoFile.fileName {
            
            let url = URL(fileURLWithPath: fileName)
            
            let startVC = DUBStartViewController()
            startVC.videoUrl = url as URL
            navigationController?.pushViewController(startVC, animated: true)
        }
    }
}
