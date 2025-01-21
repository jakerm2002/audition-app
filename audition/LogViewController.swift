//
//  LogViewController.swift
//  audition
//
//  Created by Jake Medina on 1/18/25.
//

import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var commits = [Commit]()
    
    let logViewCellIdentifier = "LogViewCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        print("LogViewController commits: ", commits)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: logViewCellIdentifier, for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        let commit = commits[indexPath.row]
        config.text = commit.message
        // will .prefix fail if the commit string for whatever reason is less than 7 chars?
        config.secondaryText = "\(commit.sha256DigestValue!.prefix(7))  \(DateFormatter.localizedString(from: commit.timestamp, dateStyle: .medium, timeStyle: .short))"
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
