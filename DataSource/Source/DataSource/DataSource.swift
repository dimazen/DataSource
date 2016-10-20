
import Foundation
import Observer

open class DataSource<Object> {
    
    // MARK: - Init
    
    open init() {}
    
    // MARK: - Observation
    
    private let observers = DisablingObserverSet<Event>()

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
    
    open func section(at index: Int) -> Section<Object> {
        fatalError("Not Implemented")
    }
    
    open func numberOfObjects(inSection section: Int) -> Int {
        return sectionAtIndex(section).numberOfObjects
    }
    
    open func object(at indexPath: IndexPath) -> Object {
        return section(at: indexPath.section).objects[indexPath.item]
    }
    
    open subscript(indexPath: IndexPath) -> Object {
        return object(at: indexPath)
    }
    
    open subscript(index: Int) -> Section<Object> {
        return section(at: index)
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
    
    open var isEmpty: Bool {
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
