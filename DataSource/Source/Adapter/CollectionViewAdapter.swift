
import Foundation
import UIKit
import Observer

open class CollectionViewAdapter<Object>: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Init

    deinit {
        disposable?.dispose()
    }
    
    public override init() {}
    
    // MARK: - DataSource

    fileprivate var disposable: Disposable?
    
    open var dataSource: DataSource<Object>! {
        didSet {
            disposable?.dispose()
            disposable = dataSource?.observe { [unowned self] event in
                self.handleEvent(event)
            }
        }
    }
    
    // MARK: - CollectionView 
    
    open var collectionView: UICollectionView! {
        didSet {
            oldValue?.dataSource = nil
            oldValue?.delegate = nil
            
            collectionView?.dataSource = self
            collectionView?.delegate = self
        }
    }
    
    // MARK: - Reloading
    
    open func reload(_ animated: Bool = false) {
        if animated {
            let range = NSMakeRange(0, collectionView.numberOfSections)
            collectionView.reloadSections(IndexSet(integersIn: range.toRange() ?? 0..<0))
        } else {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Mapping
  
    fileprivate var registeredMappers: [ObjectMappable] = []
    
    open func registerMapper(_ mapper: ObjectMappable) {
        registeredMappers.append(mapper)
    }
    
    fileprivate func mapperForObject(_ object: Object) -> ObjectMappable? {
        if let index = registeredMappers.index(where: { $0.supportsObject(object) }) {
            return registeredMappers[index]
        }
        
        return nil
    }
    
    // MARK: - Event Handling
    
    fileprivate var pendingEvents: [Event] = []
    fileprivate var collectUpdateEvents = false
    
    fileprivate func handleEvent(_ event: Event) {
        switch event {
        case .invalidate:
            // no-op
            break
            
        case .reload:
            collectionView.reloadData()
          
        case .willBeginUpdate:
            collectUpdateEvents = true
            
        case .didEndUpdate:
            collectUpdateEvents = false
            applyEvents(pendingEvents)
            pendingEvents.removeAll()
            
        case .objectUpdate(let change):
            if collectUpdateEvents {
                pendingEvents.append(event)
            } else {
                applyObjectChange(change)
            }

        case .sectionUpdate(let change):
            if collectUpdateEvents {
                pendingEvents.append(event)
            } else {
                applySectionChange(change)
            }
        }
    }
    
    fileprivate func applyEvents(_ events: [Event]) {
        for event in events {
            switch event {
            case .objectUpdate(let change):
                applyObjectChange(change)
                
            case .sectionUpdate(let change):
                applySectionChange(change)
                
            default:
                break
            }
        }
    }
    
    fileprivate func applyObjectChange(_ change: ObjectChange) {
        switch change.type {
        case .insert:
            collectionView.insertItems(at: [change.target as IndexPath])
            
        case .delete:
            collectionView.deleteItems(at: [change.source as IndexPath])
            
        case .move:
            collectionView.moveItem(at: change.source as IndexPath, to: change.target as IndexPath)
            
        case .update:
            collectionView.reloadItems(at: [change.source as IndexPath])
        }
    }
    
    fileprivate func applySectionChange(_ change: SectionChange) {
        switch change.type {
        case .insert:
            collectionView.insertSections(change.indexes as IndexSet)
    
        case .delete:
            collectionView.deleteSections(change.indexes as IndexSet)
            
        case .move:
            abort()
            
        case .update:
            collectionView.reloadSections(change.indexes as IndexSet)
        }
    }
    
    // MARK: - UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.sectionsCount
    }
  
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfObjectsInSection(section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let object = dataSource.objectAtIndexPath(indexPath)
        guard let mapper = mapperForObject(object) else {
            fatalError("You have to provide mapper that supports \(type(of: object))")
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: mapper.cellIdentifier, for: indexPath)
        mapper.mapObject(object, toCell: cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public typealias Confirmation = (Object, IndexPath) -> Bool
    
    open var shouldSelect: Confirmation?

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let object = dataSource.objectAtIndexPath(indexPath)
        return shouldSelect?(object, indexPath) ?? true
    }
    
    open var shouldDeselect: Confirmation?
    
    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let object = dataSource.objectAtIndexPath(indexPath)
        return shouldDeselect?(object, indexPath) ?? true
    }
    
    public typealias Selection = (Object, IndexPath) -> Void
    
    open var didSelect: Selection?
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = dataSource.objectAtIndexPath(indexPath)
        didSelect?(object, indexPath)
    }
    
    open var didDeselect: Selection?
    
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let object = dataSource.objectAtIndexPath(indexPath)
        didDeselect?(object, indexPath)
    }
    
    // MARK: - UIScrollViewDelegate
    
    open var didScroll: ((UIScrollView) -> Void)?
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView)
    }
}
