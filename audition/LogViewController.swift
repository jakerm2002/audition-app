//
//  LogViewController.swift
//  audition
//
//  Created by Jake Medina on 1/18/25.
//

import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let logViewCellIdentifier = "LogViewCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: logViewCellIdentifier, for: indexPath)
        return cell
    }
}
