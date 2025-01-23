//
//  ViewController.swift
//  audition
//
//  Created by Jake Medina on 5/6/23.
//

import UIKit
import PencilKit
import CoreData

var count = 0

protocol DrawingModifiable {
    func setDrawingData(commit: Commit)
}

class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, DrawingModifiable, AuditionDataModelDelegate {
    
    var canvasView = PKCanvasView()
    
    let canvasWidth: CGFloat = 768
    let canvasOverscrollHeight: CGFloat = 500
    
    let toolPicker = PKToolPicker()
    
    var dataModelFromHomeVC: AuditionDataModel?
    
    let drawingToLogSegueIdentifier = "DrawingToLogSegueIdentifier"

    @IBOutlet weak var commitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        dataModelFromHomeVC?.delegate = self
        if let dataModelFromHomeVC {
            setCommitButtonBranch(branch: dataModelFromHomeVC.HEAD)
        }
        
        // TODO: for our current implementation where each drawing is contained in one blob,
        // we need to find the most recent blob and use the data from it to create a PKDrawing.
        do {
            let mostRecentBlob = try dataModelFromHomeVC?.showBlobs()[0]
            canvasView.drawing = try PKDrawing(data: mostRecentBlob!.contents)
        } catch {
            print("error: DrawingViewController could not load Blob")
        }
        view.addSubview(canvasView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
    }
    
    func setCommitButtonBranch(branch: String) {
        commitButton.setTitle("Commit to '\(branch)'", for: .normal)
    }
    
    func storeDrawing() {
        // store a drawing commit into core data
        let name = "Drawing \(count)"
        let currentDate = Date()
        let currentDrawing = canvasView.drawing.dataRepresentation()
        let currentThumbnail = canvasView.drawing.image(from: canvasView.drawing.bounds, scale: 1.0).jpegData(compressionQuality: 1.0)
        print(currentThumbnail! as Data)
        count += 1
        
        let entry = NSEntityDescription.insertNewObject(
            forEntityName: "Drawing",
            into: context
        )
        
        entry.setValue(name, forKey: "name")
        entry.setValue(currentDate, forKey: "createdAt")
        entry.setValue(currentDrawing, forKey: "drawing")
        entry.setValue(currentThumbnail, forKey: "thumbnail")
        
        saveContext()
        
        print("drawing saved")
    }
    
    func storeDataModel() throws {
        try dataModelFromHomeVC?.add(AuditionFile(content: canvasView.drawing.dataRepresentation(), name: "drawing"))
        _ = try dataModelFromHomeVC?.commit(message: "new drawing")
    }
    
    func setDrawingData(commit: Commit) {
        do {
            // grab the blob that was included in the commit
            // we're assuming there will only be one, this will NOT BE TRUE in the future
            // once we are committing individual strokes instead of the entire drawing
            let aBlob = try dataModelFromHomeVC?.showBlobs(commit: commit.sha256DigestValue!)[0]
            let d = try PKDrawing(data: aBlob!.contents)
            let new = PKCanvasView()
            new.drawing = d
            canvasView.removeFromSuperview()
            canvasView = new
            view.addSubview(canvasView)
            
        } catch {
            print("error: DrawingViewController could not load/set drawing data")
        }
    }
    
    func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func headDidChange(_ newValue: String) {
        setCommitButtonBranch(branch: newValue)
    }
    
    @IBAction func branchButtonPressed(_ sender: Any) {
        print("branch button pressed")
        let count = dataModelFromHomeVC?.branches.count
        do {
            let branchName = "branch \(count!)"
            try dataModelFromHomeVC?.checkout(branch: branchName, newBranch: true)
            displayAlert(title: "Branch created", msg: "You are now on branch '\(branchName)'")
            
        } catch let error {
            displayError(msg: "\(error)")
        }
    }
    
    @IBAction func commitButtonPressed(_ sender: Any) {
        print("commit button pressed")
        
        if canvasView.drawing.bounds.isEmpty {
            print("Drawing is empty, skipping commit.")
        } else {
            do {
                try storeDataModel()
            } catch {
                print("Storing data model failed")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == drawingToLogSegueIdentifier, let destination = segue.destination as? LogViewController {
            // compile the commits, then send them over
            do {
                destination.delegate = self
                let commits: [Commit] = try dataModelFromHomeVC!.log()
                destination.commits = commits
                destination.title = "Commits from \(commits.first!.sha256DigestValue!.prefix(7))"
            } catch let error {
                displayError(msg: "error: Failed to compile commits and send to LogViewController: \(error)")
            }
        }
    }
    
    func displayError(msg: String) {
        displayAlert(title: "Error", msg: msg)
    }
    
    func displayAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: {
            _ in NSLog(msg)
            self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
            self.toolPicker.addObserver(self.canvasView)
            self.canvasView.becomeFirstResponder()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
