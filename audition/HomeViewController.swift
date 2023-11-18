//
//  HomeViewController.swift
//  audition
//
//  Created by Jake Medina on 11/15/23.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        navigationItem.backButtonDisplayMode = .minimal
//        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Sup", style: .plain, target: nil, action: nil)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
        print("sup")
    }
    

}
