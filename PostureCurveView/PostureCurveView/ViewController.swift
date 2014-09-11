//
//  ViewController.swift
//  PostureCurveView
//
//  Created by Monisha White on 9/10/14.
//  Copyright (c) 2014 Monisha White. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var myPostureCurveView = PostureCurveView(frame: CGRectMake(30, 30, 250, 250))
    

    @IBOutlet weak var angle1: UITextField!
    @IBOutlet weak var angle2: UITextField!
    @IBOutlet weak var angle3: UITextField!
    @IBOutlet weak var angle4: UITextField!
    @IBOutlet weak var angle5: UITextField!
    @IBOutlet weak var angle6: UITextField!
    @IBOutlet weak var accel1: UITextField!
    @IBOutlet weak var accel2: UITextField!
    
    @IBAction func angleDidChange(sender: AnyObject)
    {
        myPostureCurveView.angleChange(angle1.text.toInt()!, angle2: angle2.text.toInt()!, angle3: angle3.text.toInt()!, angle4: angle4.text.toInt()!, angle5: angle5.text.toInt()!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    func setupView()
    {
        view.addSubview(myPostureCurveView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

