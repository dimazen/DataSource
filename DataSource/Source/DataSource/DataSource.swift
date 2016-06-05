
import Foundation
import Observer

public class DataSource<Object> {
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Observation
    
    private let observers = DisablingObserverSet<Event>()

    public func observe(changes: Event -> Void) -> Disposable {
        return observers.add(changes)
    }
    
    public func send(event: Event) {
        observers.send(event)
    }
    
    public func enableEvents() {
        observers.enable()
    }
    
    public func disableEvents() {
        observers.disable()
    }
    
    // MARK: - Data Access
    
    public var sectionsCount: Int {
        fatalError("Not Implemented")
    }
    
    public func sectionAtIndex(index: Int) -> Section<Object> {
        fatalError("Not Implemented")
    }
    
    public func numberOfObjectsInSection(section: Int) -> Int {
        return sectionAtIndex(section).numberOfObjects
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> Object {
        return sectionAtIndex(indexPath.section).objects[indexPath.item]
    }
    
    public subscript(indexPath: NSIndexPath) -> Object {
        return objectAtIndexPath(indexPath)
    }
    
    public subscript(index: Int) -> Section<Object> {
        return sectionAtIndex(index)
    }
      
    // MARK: - Reload
    
    public func invalidate() {
        send(.Invalidate)
    }
    
    public func reload() {
        send(.Reload)
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