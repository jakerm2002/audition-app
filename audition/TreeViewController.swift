//
//  TreeViewController.swift
//  audition
//
//  Created by Jake Medina on 11/18/23.
//

import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let context = appDelegate.persistentContainer.viewContext

extension Data {
    public var bytes: [UInt8]
    {
        return [UInt8](self)
    }
}

class TreeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let treeViewCellIdentifier = "TreeViewCellIdentifier"
    
    var drawingList: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self

        // Do any additional setup after loading the view.
        drawingList = retrieveDrawings()
        collectionView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("collection view has \(drawingList.count) drawings")
        return drawingList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: treeViewCellIdentifier, for: indexPath) as! TreeCollectionViewCell
        if let thumbnailData = drawingList[indexPath.row].value(forKey: "thumbnail") {
            cell.imageView.image = UIImage(data: thumbnailData as! Data, scale: 4)
//            cell.imageView.image = UIImage(systemName: "person.crop.circle.fill")
            print("test", thumbnailData)
        }
        return cell
    }
    
    
    func retrieveDrawings() -> [NSManagedObject] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Drawing")
        var fetchedResults: [NSManagedObject]? = nil
        
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
            print("retrieved \(fetchedResults!.count) drawings")
        } catch {
            print("error occurred while retrieving data")
        }
        
        return (fetchedResults)!
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
