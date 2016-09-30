//
//  HeaderCollectionReusableView.swift
//  CollectionViewWaterfallLayoutDemo
//
//  Created by 최준호 on 2016. 9. 29..
//  Copyright © 2016년 Eric Cerney. All rights reserved.
//

import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {
    weak var delegate: CollectionViewWaterfallLayoutDelegate?
    weak var collectionView: UICollectionView?
    
    var section = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func buttonTap() {
        if delegate != nil && collectionView != nil {
            let layout = collectionView!.collectionViewLayout as! CollectionViewWaterfallLayout
            var headerHeight: Float
            var isDirect = false
            if let height = delegate?.collectionView?(collectionView!, layout: layout, heightForHeaderInSection: section) {
                headerHeight = height
            }
            else {
                isDirect = true
                headerHeight = Float(self.frame.size.height)
            }
            headerHeight = (headerHeight > 100) ? 100 : 200
            
            if let _ = delegate?.collectionView?(collectionView!, height: headerHeight, heightForHeaderInSection: 0) {
                if (isDirect) {
                    layout.headerHeight = headerHeight
                    layout.invalidateLayout()
                }
            }
        }
    }
}
