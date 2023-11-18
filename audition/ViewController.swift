//
//  ViewController.swift
//  audition
//
//  Created by Jake Medina on 5/6/23.
//

import UIKit
import PencilKit

class ViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
//    private let canvasView: PKCanvasView = {
//        let canvas = PKCanvasView()
//        return canvas
//    }()
    
    let canvasView = PKCanvasView()
    
    let canvasWidth: CGFloat = 768
    let canvasOverscrollHeight: CGFloat = 500
    
    var drawing = PKDrawing()
    
    let toolPicker = PKToolPicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        canvasView.delegate = self
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        view.addSubview(canvasView)
        
////        navigationItem.title = "Hello"
//        navigationItem.title = nil
//        let button = UIButton(type: .system)
//        button.setTitle("Hey", for: .normal)
//        button.setTitleColor(.blue, for: .normal)
//        navigationItem.titleView?.addSubview(button)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
    }
    
    @IBAction func commitButtonPressed(_ sender: Any) {
        
    }
    
}

