//
//  ViewController.swift
//  WaterfallFlowLayout
//
//  Created by Eric Cerney on 7/21/14.
//  Copyright (c) 2014 Eric Cerney. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, CollectionViewWaterfallLayoutDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    var headerHeight:Float = 100
    
    lazy var cellSizes: [CGSize] = {
        var _cellSizes = [CGSize]()
        
        for _ in 0...100 {
            let random = Int(arc4random_uniform((UInt32(100))))
            
            _cellSizes.append(CGSize(width: 140, height: 50 + random))
        }
        
        return _cellSizes
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let layout = CollectionViewWaterfallLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.headerInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.headerHeight = self.headerHeight
        layout.footerHeight = 20
        layout.minimumColumnSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        layout.headerStickyInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.headerStickyHeight = 50
        
        collectionView.collectionViewLayout = layout
        //collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderSticky")
        let headerNib = UINib(nibName: "HeaderCollectionReusableView", bundle: nil)
        collectionView.registerNib(headerNib, forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionFooter, withReuseIdentifier: "Footer")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellSizes.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        
        if let label = cell.contentView.viewWithTag(1) as? UILabel {
            label.text = String(indexPath.row)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: UICollectionReusableView? = nil
        
        if kind == CollectionViewWaterfallElementKindSectionHeader {
            reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath)
            
            if let stickyView = reusableView as? HeaderCollectionReusableView {
                stickyView.delegate = self
                stickyView.collectionView = self.collectionView
                stickyView.section = indexPath.section
            }
        }
        else if kind == CollectionViewWaterfallElementKindSectionFooter {
            reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Footer", forIndexPath: indexPath)
            if let view = reusableView {
                view.backgroundColor = UIColor.blueColor()
            }
        }
        else if kind == UICollectionElementKindSectionHeader {
            reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "HeaderSticky", forIndexPath: indexPath)
        }
        
        return reusableView!
    }
    
    // MARK: WaterfallLayoutDelegate
    
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSizes[indexPath.item]
    }
    
    
    
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> Float {
        return self.headerHeight
    }
    
    func collectionView(collectionView: UICollectionView, height: Float, heightForHeaderInSection section: Int) -> Bool {
        let layout = collectionView.collectionViewLayout as! CollectionViewWaterfallLayout
        
        self.headerHeight = height
        layout.headerHeight = self.headerHeight
        layout.invalidateLayout()
        
        return true
    }
}

