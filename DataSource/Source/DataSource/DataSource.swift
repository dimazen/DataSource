
import Foundation
import Observer

open class DataSource<Object> {
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Observation
    
    fileprivate let observers = DisablingObserverSet<Event>()

    open func observe(_ changes: (Event) -> Void) -> Disposable {
        return observers.add(changes)
    }
    
    open func send(_ event: Event) {
        observers.send(event)
    }
    
    open func enableEvents() {
        observers.enable()
    }
    
    open func disableEvents() {
        observers.disable()
    }
    
    // MARK: - Data Access
    
    open var sectionsCount: Int {
        fatalError("Not Implemented")
    }
    
    open func sectionAtIndex(_ index: Int) -> Section<Object> {
        fatalError("Not Implemented")
    }
    
    open func numberOfObjectsInSection(_ section: Int) -> Int {
        return sectionAtIndex(section).numberOfObjects
    }
    
    open func objectAtIndexPath(_ indexPath: IndexPath) -> Object {
        return sectionAtIndex((indexPath as NSIndexPath).section).objects[(indexPath as NSIndexPath).item]
    }
    
    open subscript(indexPath: IndexPath) -> Object {
        return objectAtIndexPath(indexPath)
    }
    
    open subscript(index: Int) -> Section<Object> {
        return sectionAtIndex(index)
    }
      
    // MARK: - Reload
    
    open func invalidate() {
        send(.invalidate)
    }
    
    open func reload() {
        send(.reload)
    }
}

extension DataSource {
    
    public var isEmpty: Bool {
        if sectionsCount == 0 {
            return true
        }
        
        for index in 0..<sectionsCount {
            if numberOfObjectsInSection(index) > 0 {
                return false
            }
        }
        
        return true
    }
}
