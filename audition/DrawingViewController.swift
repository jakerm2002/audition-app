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

class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    let canvasView = PKCanvasView()
    
    let canvasWidth: CGFloat = 768
    let canvasOverscrollHeight: CGFloat = 500
    
    let toolPicker = PKToolPicker()
    
    var dataModelFromHomeVC: AuditionDataModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        view.addSubview(canvasView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
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
    
    func storeDataModel() {
        
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
    
    @IBAction func commitButtonPressed(_ sender: Any) {
        print("commit button pressed")
        
        if canvasView.drawing.bounds.isEmpty {
            print("Drawing is empty, skipping commit.")
        } else {
            storeDrawing()
        }
    }
    
}
