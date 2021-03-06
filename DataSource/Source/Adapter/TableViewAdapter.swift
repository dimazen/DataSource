
import Foundation
import UIKit
import Observer

open class TableViewAdapter<Object>: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Init
    
    deinit {
        disposable?.dispose()
    }
    
    public override init() {}
    
    // MARK: - DataSource
    
    private var disposable: Disposable?
    
    open var dataSource: DataSource<Object>! {
        didSet {
            disposable?.dispose()
            disposable = dataSource?.observe { [unowned self] event in
                self.handleEvent(event)
            }
        }
    }

    // MARK: - CollectionView
    
    open var tableView: UITableView! {
        didSet {
            oldValue?.dataSource = nil
            oldValue?.delegate = nil
            
            tableView?.dataSource = self
            tableView?.delegate = self
        }
    }
    
    // MARK: - Reloading
    
    open func reload(animated: Bool = false) {
        if animated {
            tableView.reloadSections(IndexSet(integersIn: 0..<tableView.numberOfSections), with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
    
    open func reload(at indexPath: IndexPath, animated: Bool) {
        tableView.reloadRows(at: [indexPath], with: animated ? .automatic : .none)
    }
    
    // MARK: - Mapping
    
    private var registeredMappers: [ObjectMappable] = []
    
    open func register(_ mapper: ObjectMappable) {
        registeredMappers.append(mapper)
    }
    
    private func mapper(for object: Object) -> ObjectMappable? {
        if let index = registeredMappers.index(where: { $0.supports(object) }) {
            return registeredMappers[index]
        }
        
        return nil
    }
    
    // MARK: - Event Handling
    
    private var pendingEvents: [Event] = []
    private var collectUpdateEvents = false
    
    private func handleEvent(_ event: Event) {
        switch event {
        case .invalidate:
            // no-op
            break
            
        case .reload:
            tableView.reloadData()
            
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
    
    private func applyEvents(_ events: [Event]) {
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
    
    private func applyObjectChange(_ change: ObjectChange) {
        switch change.type {
        case .insert:
            tableView.insertRows(at: [change.target as IndexPath], with: .automatic)
            
        case .delete:
            tableView.deleteRows(at: [change.source as IndexPath], with: .automatic)
            
        case .move:
            tableView.moveRow(at: change.source as IndexPath, to: change.target as IndexPath)
            
        case .update:
            tableView.reloadRows(at: [change.source as IndexPath], with: .automatic)
        }
    }
    
    private func applySectionChange(_ change: SectionChange) {
        switch change.type {
        case .insert:
            tableView.insertSections(change.indexes as IndexSet, with: .automatic)
            
        case .delete:
            tableView.deleteSections(change.indexes as IndexSet, with: .automatic)
            
        case .move:
            abort()
            
        case .update:
            tableView.reloadSections(change.indexes as IndexSet, with: .automatic)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.sectionsCount
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfObjects(inSection: section)
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = dataSource.object(at: indexPath)
        guard let mapper = mapper(for: object) else {
            fatalError("You have to provide mapper that supports \(type(of: object))")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: mapper.cellIdentifier, for: indexPath)
        mapper.map(object: object, toCell: cell, at: indexPath)
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    public typealias Selection = (Object, IndexPath) -> Void
    
    open var didSelect: Selection?
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = dataSource.object(at: indexPath)
        didSelect?(object, indexPath)
    }
    
    open var didDeselect: Selection?
    
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let object = dataSource.object(at: indexPath)
        didDeselect?(object, indexPath)
    }
    
    // MARK: - UIScrollViewDelegate
    
    open var didScroll: ((UIScrollView) -> Void)?
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView)
    }
}
