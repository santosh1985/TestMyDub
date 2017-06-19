//
//  DUBHomeViewController.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/13/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit

class DUBHomeViewController: UIViewController {

    //MARK: - Factory methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.purple
        
        addTitle()
        addButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
}

//MARK: - UI Setup
extension DUBHomeViewController {
    
    /**
     Add the Dubsmash title on top of the screen
     */
    fileprivate func addTitle() {
        let titleRect = CGRect(x: 30, y: 30, width: view.frame.size.width - 60, height: 100)
        let titleLabel = UILabel(frame: titleRect)
        
        titleLabel.text = "Dubsmash"
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "Marker Felt", size: 60.0)
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(titleLabel)
    }
    
    /**
     Add two buttons to record a new DUB and list out old DUBs
     */
    fileprivate func addButtons() {
        let newButtonRect = CGRect(x: 30, y: view.frame.size.height/3 - 30, width: view.frame.size.width - 60, height: 100)
        let newButton = UIButton.init(frame: newButtonRect)
        newButton.backgroundColor = UIColor.white
        newButton.layer.cornerRadius = 5.0
        newButton.setAttributedTitle(NSAttributedString.init(string: "New Dub", attributes: [NSFontAttributeName: UIFont(name: "Marker Felt", size: 36.0) as Any, NSForegroundColorAttributeName: UIColor.black]), for: .normal)
        newButton.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(newButton)
        newButton.addTarget(self, action: #selector(newDubButtonTapped), for: .touchUpInside)
        
        let oldButtonRect = CGRect(x: 30, y: view.frame.size.height/2 + 30, width: view.frame.size.width - 60, height: 100)
        let oldButton = UIButton.init(frame: oldButtonRect)
        oldButton.backgroundColor = UIColor.white
        oldButton.layer.cornerRadius = 5.0
        oldButton.setAttributedTitle(NSAttributedString.init(string: "Old Dubs", attributes: [NSFontAttributeName: UIFont(name: "Marker Felt", size: 36.0) as Any, NSForegroundColorAttributeName: UIColor.black]), for: .normal)
        oldButton.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(oldButton)
        oldButton.addTarget(self, action: #selector(oldDubsButtonTapped), for: .touchUpInside)
    }
}

//MARK: - Actions
extension DUBHomeViewController {
    
    func newDubButtonTapped() {
        
        let dubStartVC = DUBStartViewController()
        navigationController?.pushViewController(dubStartVC, animated: true)
    }
    
    func oldDubsButtonTapped() {
        
        let oldDubsVC = DUBTableViewController()
        oldDubsVC.view.backgroundColor = UIColor.blue
        navigationController?.pushViewController(oldDubsVC, animated: true)
    }
}
