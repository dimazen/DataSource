
import Foundation

final public class ArrayDataSource<Object>: DataSource<Object> {
    
    private let resolver: (Void -> [ArraySection<Object>])?
    
    // MARK: - Init
    
    public init(resolver: Void -> [ArraySection<Object>]) {
        self.resolver = resolver
    }
    
    convenience public init(objects: [Object]) {
        self.init {
            return [ArraySection(objects: objects)]
        }
    }
    
    convenience public init(resolver: Void -> [[Object]]) {
        self.init {
            return resolver().map { ArraySection(objects: $0) }
        }
    }
    
    override public init() {
        resolver = nil
    }
    
    // MARK: - Batch Update

    private var updating: Bool = false

    public func beginUpdate() {
        precondition(updating == false)
        updating = true

        send(.WillBeginUpdate)
    }

    public func endUpdate() {
        precondition(updating == true)
        updating = false

        send(.DidEndUpdate)
    }

    public func apply(silently: Bool = false, @noescape changes: Void -> Void) {
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

    private var invalidated: Bool = true
    
    override public func invalidate() {
        invalidated = true
        
        send(.Invalidate)
    }

    override public func reload() {
        reload(resolver?() ?? [])
    }
    
    private func reload(sections: [ArraySection<Object>]) {
        _sections = sections
        invalidated = false
        
        send(.Reload)
    }

    // MARK: - Access
    
    private var _sections: [ArraySection<Object>] = []
    public private(set) var sections: [ArraySection<Object>] {
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
    
    public override func sectionAtIndex(index: Int) -> Section<Object> {
        return sections[index]
    }

    override public func numberOfObjectsInSection(section: Int) -> Int {
        return sections[section].numberOfObjects
    }
    
    override public func objectAtIndexPath(indexPath: NSIndexPath) -> Object {
        return sections[indexPath.section].objectAtIndex(indexPath.item)
    }
    
    // MARK: - Mutation:Objects
    
    public func appendObject(object: Object, toSection sectionIndex: Int) {
        let insertionIndex = sections[sectionIndex].objects.endIndex
        insertObject(object, atIndex: insertionIndex, toSection: sectionIndex)
    }
    
    public func appendObject(object: Object) {
        if sections.isEmpty {
            appendSection(ArraySection(objects: [object]))
        } else {
            appendObject(object, toSection: sections.endIndex - 1)
        }
    }
    
    public func insertObject(object: Object, atIndex index: Int, toSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].insert(object, atIndex: index)
            
            let change = ObjectChange(type: .Insert, target: NSIndexPath(forItem: index, inSection: sectionIndex))
            send(.ObjectUpdate(change))
        }
    }
    
    public func removeObjectAtIndex(index: Int, inSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].removeAtIndex(index)
            
            let change = ObjectChange(type: .Delete, source: NSIndexPath(forItem: index, inSection: sectionIndex))
            send(.ObjectUpdate(change))
        }
    }
    
    public func removeObjectAtIndexPath(indexPath: NSIndexPath) {
        removeObjectAtIndex(indexPath.item, inSection: indexPath.section)
    }
    
    public func replaceObjectAtIndexPath(indexPath: NSIndexPath, withObject object: Object) {
        apply {
            sections[indexPath.section][indexPath.item] = object
            
            let change = ObjectChange(type: .Update, source: indexPath)
            send(.ObjectUpdate(change))
        }
    }
    
    public func moveObjectAtIndexPath(indexPath: NSIndexPath, to toIndexPath: NSIndexPath) {
        apply {
            let object = sections[indexPath.section].removeAtIndex(indexPath.item)
            sections[toIndexPath.section].insert(object, atIndex: toIndexPath.item)
            
            let change = ObjectChange(type: .Move, source: indexPath, target: toIndexPath)
            send(.ObjectUpdate(change))
        }
    }
    
    // MARK: - Mutation:Sections
    
    public func appendSection(section: ArraySection<Object>) {
        insertSection(section, atIndex: sections.endIndex)
    }
    
    public func insertSection(section: ArraySection<Object>, atIndex index: Int) {
        apply {
            sections.insert(section, atIndex: index)

            let change = SectionChange(type: .Insert, indexes: NSIndexSet(index: index))
            send(.SectionUpdate(change))
        }
    }
    
    public func removeSectionAtIndex(index: Int) {
        apply {
            sections.removeAtIndex(index)
            
            let change = SectionChange(type: .Delete, indexes: NSIndexSet(index: index))
            send(.SectionUpdate(change))
        }
    }
    
    public func setObjects(objects: [Object]) {
        reload([ArraySection(objects: objects)])
    }

    public func setSections(sections: [ArraySection<Object>]) {
        reload(sections)
    }
    
    // MARK: - Search
    
    public func indexPathOf(predicate: Object -> Bool) -> NSIndexPath? {
        for (sectionIndex, section) in sections.enumerate() {
            for (objectIndex, object) in section.objects.enumerate() {
                if predicate(object) {
                    return NSIndexPath(forItem: objectIndex, inSection: sectionIndex)
                }
            }
        }
        
        return nil
    }
}

extension ArrayDataSource where Object: Equatable {
 
    public func removeObject(object: Object) {
        if let indexPath = indexPathOf(object) {
            removeObjectAtIndexPath(indexPath)
        }
    }
    
    /**
     Complexity O(n)
     */
    public func indexPathOf(object: Object) -> NSIndexPath? {
        for index in 0..<sectionsCount {
            if let objectIndex = sections[index].indexOf(object) {
                return NSIndexPath(forItem: objectIndex, inSection: index)
            }
        }
        
        return nil
    }
}