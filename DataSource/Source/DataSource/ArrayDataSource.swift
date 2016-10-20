
import Foundation

final public class ArrayDataSource<Object>: DataSource<Object> {
    
    fileprivate let resolver: ((Void) -> [ArraySection<Object>])?
    
    // MARK: - Init
    
    public init(resolver: @escaping (Void) -> [ArraySection<Object>]) {
        self.resolver = resolver
    }
    
    convenience public init(objects: [Object]) {
        self.init {
            return [ArraySection(objects: objects)]
        }
    }
    
    convenience public init(resolver: @escaping (Void) -> [[Object]]) {
        self.init {
            return resolver().map { ArraySection(objects: $0) }
        }
    }
    
    override public init() {
        resolver = nil
    }
    
    // MARK: - Batch Update

    fileprivate var updating: Bool = false

    public func beginUpdate() {
        precondition(updating == false)
        updating = true

        send(.willBeginUpdate)
    }

    public func endUpdate() {
        precondition(updating == true)
        updating = false

        send(.didEndUpdate)
    }

    public func apply(_ silently: Bool = false, changes: (Void) -> Void) {
        if silently {
            disableEvents()
            
            defer {
                enableEvents()
            }
        }
        
        if updating {
            changes()
        } else {
            beginUpdate()
            changes()
            endUpdate()
        }
    }

    // MARK: - Invalidation

    fileprivate var invalidated: Bool = true
    
    override public func invalidate() {
        invalidated = true
        
        send(.invalidate)
    }

    override public func reload() {
        reload(resolver?() ?? [])
    }
    
    fileprivate func reload(_ sections: [ArraySection<Object>]) {
        _sections = sections
        invalidated = false
        
        send(.reload)
    }

    // MARK: - Access
    
    fileprivate var _sections: [ArraySection<Object>] = []
    public fileprivate(set) var sections: [ArraySection<Object>] {
        get {
            if invalidated {
                reload()
            }
            
            return _sections
        }
        
        set {
            _sections = newValue
        }
    }
    
    override public var sectionsCount: Int {
        return sections.count
    }
    
    public override func sectionAtIndex(_ index: Int) -> Section<Object> {
        return sections[index]
    }

    override public func numberOfObjectsInSection(_ section: Int) -> Int {
        return sections[section].numberOfObjects
    }
    
    override public func objectAtIndexPath(_ indexPath: IndexPath) -> Object {
        return sections[(indexPath as NSIndexPath).section].objectAtIndex((indexPath as NSIndexPath).item)
    }
    
    // MARK: - Mutation:Objects
    
    public func appendObject(_ object: Object, toSection sectionIndex: Int) {
        let insertionIndex = sections[sectionIndex].objects.endIndex
        insertObject(object, atIndex: insertionIndex, toSection: sectionIndex)
    }
    
    public func appendObject(_ object: Object) {
        if sections.isEmpty {
            appendSection(ArraySection(objects: [object]))
        } else {
            appendObject(object, toSection: sections.endIndex - 1)
        }
    }
    
    public func insertObject(_ object: Object, atIndex index: Int, toSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].insert(object, atIndex: index)
            
            let change = ObjectChange(type: .insert, target: IndexPath(item: index, section: sectionIndex))
            send(.objectUpdate(change))
        }
    }
    
    public func removeObjectAtIndex(_ index: Int, inSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].removeAtIndex(index)
            
            let change = ObjectChange(type: .delete, source: IndexPath(item: index, section: sectionIndex))
            send(.objectUpdate(change))
        }
    }
    
    public func removeObjectAtIndexPath(_ indexPath: IndexPath) {
        removeObjectAtIndex((indexPath as NSIndexPath).item, inSection: (indexPath as NSIndexPath).section)
    }
    
    public func replaceObjectAtIndexPath(_ indexPath: IndexPath, withObject object: Object) {
        apply {
            sections[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).item] = object
            
            let change = ObjectChange(type: .update, source: indexPath)
            send(.objectUpdate(change))
        }
    }
    
    public func moveObjectAtIndexPath(_ indexPath: IndexPath, to toIndexPath: IndexPath) {
        apply {
            let object = sections[(indexPath as NSIndexPath).section].removeAtIndex((indexPath as NSIndexPath).item)
            sections[(toIndexPath as NSIndexPath).section].insert(object, atIndex: (toIndexPath as NSIndexPath).item)
            
            let change = ObjectChange(type: .move, source: indexPath, target: toIndexPath)
            send(.objectUpdate(change))
        }
    }
    
    // MARK: - Mutation:Sections
    
    public func appendSection(_ section: ArraySection<Object>) {
        insertSection(section, atIndex: sections.endIndex)
    }
    
    public func insertSection(_ section: ArraySection<Object>, atIndex index: Int) {
        apply {
            sections.insert(section, at: index)

            let change = SectionChange(type: .insert, indexes: IndexSet(integer: index))
            send(.sectionUpdate(change))
        }
    }
    
    public func removeSectionAtIndex(_ index: Int) {
        apply {
            sections.remove(at: index)
            
            let change = SectionChange(type: .delete, indexes: IndexSet(integer: index))
            send(.sectionUpdate(change))
        }
    }
    
    public func setObjects(_ objects: [Object]) {
        reload([ArraySection(objects: objects)])
    }

    public func setSections(_ sections: [ArraySection<Object>]) {
        reload(sections)
    }
    
    // MARK: - Search
    
    public func indexPathOf(_ predicate: (Object) -> Bool) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for (objectIndex, object) in section.objects.enumerated() {
                if predicate(object) {
                    return IndexPath(item: objectIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
}

extension ArrayDataSource where Object: Equatable {
 
    public func removeObject(_ object: Object) {
        if let indexPath = indexPathOf(object) {
            removeObjectAtIndexPath(indexPath)
        }
    }
    
    /**
     Complexity O(n)
     */
    public func indexPathOf(_ object: Object) -> IndexPath? {
        for index in 0..<sectionsCount {
            if let objectIndex = sections[index].indexOf(object) {
                return IndexPath(item: objectIndex, section: index)
            }
        }
        
        return nil
    }
}
