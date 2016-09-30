//
//  CollectionViewWaterfallLayout.swift
//  CollectionViewWaterfallLayout
//
//  Created by Eric Cerney on 7/21/14.
//  Based on CHTCollectionViewWaterfallLayout by Nelson Tai
//  Copyright (c) 2014 Eric Cerney. All rights reserved.
//

import UIKit

public let CollectionViewWaterfallElementKindSectionHeader = "CollectionViewWaterfallElementKindSectionHeader"
public let CollectionViewWaterfallElementKindSectionFooter = "CollectionViewWaterfallElementKindSectionFooter"

@objc public protocol CollectionViewWaterfallLayoutDelegate:UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> Float
    
    optional func collectionView(collectionView: UICollectionView, height: Float, heightForHeaderInSection section: Int) -> Bool
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, heightForFooterInSection section: Int) -> Float
    
    optional func collectionView(collectionView: UICollectionView, height: Float, heightForFooterInSection section: Int) -> Void
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSection section: Int) -> UIEdgeInsets
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, insetForHeaderInSection section: Int) -> UIEdgeInsets
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, insetForFooterInSection section: Int) -> UIEdgeInsets
    
    optional func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, minimumInteritemSpacingForSection section: Int) -> Float
    
}

public class CollectionViewWaterfallLayout: UICollectionViewLayout {
    
    //MARK: Private constants
    /// How many items to be union into a single rectangle
    private let unionSize = 20;
    
    //MARK: Public Properties
    public var columnCount:Int = 2 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: columnCount)
        }
    }
    public var minimumColumnSpacing:Float = 10.0 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: minimumColumnSpacing)
        }
    }
    public var minimumInteritemSpacing:Float = 10.0 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: minimumInteritemSpacing)
        }
    }
    public var headerHeight:Float = 0.0 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: headerHeight)
        }
    }
    public var footerHeight:Float = 0.0 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: footerHeight)
        }
    }
    public var headerInset:UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            invalidateIfNotEqual(NSValue(UIEdgeInsets: oldValue), newValue: NSValue(UIEdgeInsets: headerInset))
        }
    }
    public var footerInset:UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            invalidateIfNotEqual(NSValue(UIEdgeInsets: oldValue), newValue: NSValue(UIEdgeInsets: footerInset))
        }
    }
    public var sectionInset:UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            invalidateIfNotEqual(NSValue(UIEdgeInsets: oldValue), newValue: NSValue(UIEdgeInsets: sectionInset))
        }
    }
    
    public var headerStickyHeight:Float = 0.0 {
        didSet {
            invalidateIfNotEqual(oldValue, newValue: headerStickyHeight)
        }
    }
    public var headerStickyInset:UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            invalidateIfNotEqual(NSValue(UIEdgeInsets: oldValue), newValue: NSValue(UIEdgeInsets: headerStickyInset))
        }
    }
    
    //MARK: Private Properties
    private weak var delegate: CollectionViewWaterfallLayoutDelegate?  {
        get {
            return collectionView?.delegate as? CollectionViewWaterfallLayoutDelegate
        }
    }
    private var columnHeights = [Float]()
    private var sectionItemAttributes = [[UICollectionViewLayoutAttributes]]()
    private var allItemAttributes = [UICollectionViewLayoutAttributes]()
    private var headersStickyAttribute = [Int: UICollectionViewLayoutAttributes]()
    private var headersAttribute = [Int: UICollectionViewLayoutAttributes]()
    private var footersAttribute = [Int: UICollectionViewLayoutAttributes]()
    private var unionRects = [CGRect]()
    
    
    //MARK: UICollectionViewLayout Methods
    override public func prepareLayout() {
        super.prepareLayout()
        
        let numberOfSections = collectionView?.numberOfSections()
        
        if numberOfSections == 0 {
            return;
        }
        
        assert(delegate!.conformsToProtocol(CollectionViewWaterfallLayoutDelegate), "UICollectionView's delegate should conform to WaterfallLayoutDelegate protocol")
        assert(columnCount > 0, "WaterfallFlowLayout's columnCount should be greater than 0")
        
        // Initialize variables
        headersStickyAttribute.removeAll(keepCapacity: false)
        headersAttribute.removeAll(keepCapacity: false)
        footersAttribute.removeAll(keepCapacity: false)
        unionRects.removeAll(keepCapacity: false)
        columnHeights.removeAll(keepCapacity: false)
        allItemAttributes.removeAll(keepCapacity: false)
        sectionItemAttributes.removeAll(keepCapacity: false)
        
        for _ in 0..<columnCount {
            self.columnHeights.append(0)
        }
        
        // Create attributes
        var top:Float = 0
        var attributes: UICollectionViewLayoutAttributes
        
        for section in 0..<numberOfSections! {
            /*
            * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            */
            var minimumInteritemSpacing: Float
            if let height = delegate?.collectionView?(collectionView!, layout: self, minimumInteritemSpacingForSection: section) {
                minimumInteritemSpacing = height
            }
            else {
                minimumInteritemSpacing = self.minimumInteritemSpacing
            }
            
            var sectionInset: UIEdgeInsets
            if let inset = delegate?.collectionView?(collectionView!, layout: self, insetForSection: section) {
                sectionInset = inset
            }
            else {
                sectionInset = self.sectionInset
            }
            
            let width = Float(collectionView!.frame.size.width - sectionInset.left - sectionInset.right)
            let itemWidth = floorf((width - Float(columnCount - 1) * Float(minimumColumnSpacing)) / Float(columnCount))
            
            /*
             * 2. Sticky header
             */
            if self.headerStickyHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: NSIndexPath(forItem: 0, inSection: section))
                attributes.frame = CGRect(x: self.headerStickyInset.left, y: CGFloat(top), width: collectionView!.frame.size.width - (self.headerStickyInset.left + self.headerStickyInset.right), height: CGFloat(self.headerStickyHeight))
                attributes.zIndex = 1024
                
                headersStickyAttribute[section] = attributes
                
                top = Float(CGRectGetMaxY(attributes.frame)) + Float(self.headerStickyInset.bottom)
            }
            
            /*
             * 3. Section header
             */
            var headerHeight: Float
            if let height = delegate?.collectionView?(collectionView!, layout: self, heightForHeaderInSection: section) {
                headerHeight = height
            }
            else {
                headerHeight = self.headerHeight
            }
            
            var headerInset: UIEdgeInsets
            if let inset = delegate?.collectionView?(collectionView!, layout: self, insetForHeaderInSection: section) {
                headerInset = inset
            }
            else {
                headerInset = self.headerInset
            }
            
            top += Float(headerInset.top)
            
            if headerHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionHeader, withIndexPath: NSIndexPath(forItem: 0, inSection: section))
                attributes.frame = CGRect(x: headerInset.left, y: CGFloat(top), width: collectionView!.frame.size.width - (headerInset.left + headerInset.right), height: CGFloat(headerHeight))
                attributes.zIndex = 512
                
                headersAttribute[section] = attributes
                allItemAttributes.append(attributes)
                
                top = Float(CGRectGetMaxY(attributes.frame)) + Float(headerInset.bottom)
            }
            
            top += Float(sectionInset.top)
            for idx in 0..<columnCount {
                columnHeights[idx] = top
            }
            
            
            /*
            * 4. Section items
            */
            let itemCount = collectionView!.numberOfItemsInSection(section)
            var itemAttributes = [UICollectionViewLayoutAttributes]()
            
            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = NSIndexPath(forItem: idx, inSection: section)
                let columnIndex = shortestColumnIndex()
                
                let xOffset = Float(sectionInset.left) + Float(itemWidth + minimumColumnSpacing) * Float(columnIndex)
                let yOffset = columnHeights[columnIndex]
                let itemSize = delegate?.collectionView(collectionView!, layout: self, sizeForItemAtIndexPath: indexPath)
                var itemHeight: Float = 0.0
                if itemSize?.height > 0 && itemSize?.width > 0 {
                    itemHeight = Float(itemSize!.height) * itemWidth / Float(itemSize!.width)
                }
                
                attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.frame = CGRect(x: CGFloat(xOffset), y: CGFloat(yOffset), width: CGFloat(itemWidth), height: CGFloat(itemHeight))
                itemAttributes.append(attributes)
                allItemAttributes.append(attributes)
                columnHeights[columnIndex] = Float(CGRectGetMaxY(attributes.frame)) + minimumInteritemSpacing
            }
            
            sectionItemAttributes.append(itemAttributes)
            
            /*
            * 5. Section footer
            */
            var footerHeight: Float
            let columnIndex = longestColumnIndex()
            top = columnHeights[columnIndex] - minimumInteritemSpacing + Float(sectionInset.bottom)
            
            if let height = delegate?.collectionView?(collectionView!, layout: self, heightForFooterInSection: section) {
                footerHeight = height
            }
            else {
                footerHeight = self.footerHeight
            }
            
            var footerInset: UIEdgeInsets
            if let inset = delegate?.collectionView?(collectionView!, layout: self, insetForFooterInSection: section) {
                footerInset = inset
            }
            else {
                footerInset = self.footerInset
            }
            
            top += Float(footerInset.top)
            
            if footerHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionFooter, withIndexPath: NSIndexPath(forItem: 0, inSection: section))
                attributes.frame = CGRect(x: footerInset.left, y: CGFloat(top), width: collectionView!.frame.size.width - (footerInset.left + footerInset.right), height: CGFloat(footerHeight))
                attributes.zIndex = 512
                
                footersAttribute[section] = attributes
                allItemAttributes.append(attributes)
                
                top = Float(CGRectGetMaxY(attributes.frame)) + Float(footerInset.bottom)
            }
            
            for idx in 0..<columnCount {
                columnHeights[idx] = top
            }
        }
        
        // Build union rects
        var idx = 0
        let itemCounts = allItemAttributes.count
        
        while idx < itemCounts {
            let rect1 = allItemAttributes[idx].frame
            idx = min(idx + unionSize, itemCounts) - 1
            let rect2 = allItemAttributes[idx].frame
            unionRects.append(CGRectUnion(rect1, rect2))
            idx += 1
        }
    }
    
    override public func collectionViewContentSize() -> CGSize {
        let numberOfSections = collectionView?.numberOfSections()
        if numberOfSections == 0 {
            return CGSizeZero
        }
        
        var contentSize = collectionView?.bounds.size
        contentSize?.height = CGFloat(columnHeights[0])
        
        return contentSize!
    }
    
    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section >= sectionItemAttributes.count {
            return nil
        }
        
        if indexPath.item >= sectionItemAttributes[indexPath.section].count {
            return nil
        }
        
        return sectionItemAttributes[indexPath.section][indexPath.item]
    }
    
    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attribute: UICollectionViewLayoutAttributes?
        
        if elementKind == CollectionViewWaterfallElementKindSectionHeader {
            attribute = headersAttribute[indexPath.section]
        }
        else if elementKind == CollectionViewWaterfallElementKindSectionFooter {
            attribute = footersAttribute[indexPath.section]
        }
        // If this is a header, we should tweak it's attributes
        else if elementKind == UICollectionElementKindSectionHeader {
            attribute = headersStickyAttribute[indexPath.section]
        }
        
        return attribute
    }
    
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var begin:Int = 0
        var end: Int = unionRects.count
        var attrs = [UICollectionViewLayoutAttributes]()
        
        for i in 0..<unionRects.count {
            if CGRectIntersectsRect(rect, unionRects[i]) {
                begin = i * unionSize
                break
            }
        }
        for i in (0..<unionRects.count).reverse() {
            if CGRectIntersectsRect(rect, unionRects[i]) {
                end = min((i+1) * unionSize, allItemAttributes.count)
                break
            }
        }
        for i in begin..<end {
            let attr = allItemAttributes[i]
            if CGRectIntersectsRect(rect, attr.frame) {
                attrs.append(attr)
            }
        }
        
        var superAttributes = [UICollectionViewLayoutAttributes]()
        let contentOffset = collectionView!.contentOffset
        let missingSections = NSMutableIndexSet()
        
        for layoutAttributes in attrs {
            if (layoutAttributes.representedElementCategory == .Cell) {
                missingSections.addIndex(layoutAttributes.indexPath.section)
            }
            
            if let representedElementKind = layoutAttributes.representedElementKind {
                if representedElementKind == UICollectionElementKindSectionHeader {
                    missingSections.removeIndex(layoutAttributes.indexPath.section)
                }
            }
        }
        
        missingSections.enumerateIndexesUsingBlock { idx, stop in
            let indexPath = NSIndexPath(forItem: 0, inSection: idx)
            if let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: indexPath) {
                attrs.append(layoutAttributes)
            }
        }
        
        for layoutAttributes in attrs {
            if let representedElementKind = layoutAttributes.representedElementKind {
                if representedElementKind == UICollectionElementKindSectionHeader {
                    let section = layoutAttributes.indexPath.section
                    let numberOfItemsInSection = collectionView!.numberOfItemsInSection(section)
                    
                    let firstCellIndexPath = NSIndexPath(forItem: 0, inSection: section)
                    let lastCellIndexPath = NSIndexPath(forItem: max(0, (numberOfItemsInSection - 1)), inSection: section)
                    
                    var firstCellAttributes:UICollectionViewLayoutAttributes
                    var lastCellAttributes:UICollectionViewLayoutAttributes
                    
                    if (self.collectionView!.numberOfItemsInSection(section) > 0) {
                        firstCellAttributes = (headersAttribute[section] == nil ? self.layoutAttributesForItemAtIndexPath(firstCellIndexPath)! : self.layoutAttributesForSupplementaryViewOfKind(CollectionViewWaterfallElementKindSectionHeader, atIndexPath: firstCellIndexPath)!)
                        lastCellAttributes = (footersAttribute[section] == nil ? self.layoutAttributesForItemAtIndexPath(lastCellIndexPath)! : self.layoutAttributesForSupplementaryViewOfKind(CollectionViewWaterfallElementKindSectionFooter, atIndexPath: firstCellIndexPath)!)
                    } else {
                        firstCellAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: firstCellIndexPath)!
                        lastCellAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, atIndexPath: lastCellIndexPath)!
                    }
                    
                    let headerHeight = CGRectGetHeight(layoutAttributes.frame)
                    var origin = layoutAttributes.frame.origin
                    
                    origin.y = min(max(contentOffset.y, 0), (CGRectGetMaxY(lastCellAttributes.frame) - headerHeight))
                    _ = firstCellAttributes
                    // Uncomment this line for normal behaviour:
                    //origin.y = min(max(contentOffset.y, (CGRectGetMinY(firstCellAttributes.frame) - headerHeight)), (CGRectGetMaxY(lastCellAttributes.frame) - headerHeight))
                    layoutAttributes.frame = CGRect(origin: origin, size: layoutAttributes.frame.size)
                }
            }
            superAttributes.append(layoutAttributes)
        }
        
        return Array(superAttributes)
    }
    
    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        let oldBounds = collectionView?.bounds
        if CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds!) {
            return true
        }
        
        return true
    }
    
    //MARK: Private Methods
    private func shortestColumnIndex() -> Int {
        var index: Int = 0
        var shortestHeight = MAXFLOAT
        
        for (idx, height) in columnHeights.enumerate() {
            if height < shortestHeight {
                shortestHeight = height
                index = idx
            }
        }
        
        return index
    }
    
    private func longestColumnIndex() -> Int {
        var index: Int = 0
        var longestHeight:Float = 0
        
        for (idx, height) in columnHeights.enumerate() {
            if height > longestHeight {
                longestHeight = height
                index = idx
            }
        }
        
        return index
    }
    
    private func invalidateIfNotEqual(oldValue: AnyObject, newValue: AnyObject) {
        if !oldValue.isEqual(newValue) {
            invalidateLayout()
        }
    }
}
