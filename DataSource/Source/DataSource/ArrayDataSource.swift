
import Foundation

final public class ArrayDataSource<Object>: DataSource<Object> {
    
    private let resolver: ((Void) -> [ArraySection<Object>])?
    
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

    private var updating: Bool = false

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

    public func apply(silently: Bool = false, changes: (Void) -> Void) {
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
        
        send(.invalidate)
    }

    override public func reload() {
        reload(sections: resolver?() ?? [])
    }
    
    private func reload(sections: [ArraySection<Object>]) {
        _sections = sections
        invalidated = false
        
        send(.reload)
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
    
    public override func section(at index: Int) -> Section<Object> {
        return sections[index]
    }

    override public func numberOfObjects(inSection section: Int) -> Int {
        return sections[section].numberOfObjects
    }
    
    override public func object(at indexPath: IndexPath) -> Object {
        return sections[indexPath.section].object(at: indexPath.item)
    }
    
    // MARK: - Mutation:Objects
    
    public func append(_ object: Object, toSection sectionIndex: Int) {
        let insertionIndex = sections[sectionIndex].objects.endIndex
        insert(object, at: insertionIndex, toSection: sectionIndex)
    }
    
    public func append(_ object: Object) {
        if sections.isEmpty {
            append(section: ArraySection(objects: [object]))
        } else {
            append(object, toSection: sections.endIndex - 1)
        }
    }
    
    public func insert(_ object: Object, at index: Int, toSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].insert(object, at: index)
            
            let change = ObjectChange(type: .insert, target: IndexPath(item: index, section: sectionIndex))
            send(.objectUpdate(change))
        }
    }
    
    public func remove(at index: Int, inSection sectionIndex: Int) {
        apply {
            sections[sectionIndex].remove(at: index)
            
            let change = ObjectChange(type: .delete, source: IndexPath(item: index, section: sectionIndex))
            send(.objectUpdate(change))
        }
    }
    
    public func remove(at indexPath: IndexPath) {
        remove(at: indexPath.item, inSection: indexPath.section)
    }
    
    public func replace(at indexPath: IndexPath, with object: Object) {
        apply {
            sections[indexPath.section][indexPath.item] = object
            
            let change = ObjectChange(type: .update, source: indexPath)
            send(.objectUpdate(change))
        }
    }
    
    public func move(at indexPath: IndexPath, to toIndexPath: IndexPath) {
        apply {
            let object = sections[indexPath.section].remove(at: indexPath.item)
            sections[toIndexPath.section].insert(object, at: toIndexPath.item)
            
            let change = ObjectChange(type: .move, source: indexPath, target: toIndexPath)
            send(.objectUpdate(change))
        }
    }
    
    // MARK: - Mutation:Sections
    
    public func append(section: ArraySection<Object>) {
        insert(section: section, at: sections.endIndex)
    }
    
    public func insert(section: ArraySection<Object>, at index: Int) {
        apply {
            sections.insert(section, at: index)

            let change = SectionChange(type: .insert, indexes: IndexSet(integer: index))
            send(.sectionUpdate(change))
        }
    }
    
    public func remove(sectionAt index: Int) {
        apply {
            sections.remove(at: index)
            
            let change = SectionChange(type: .delete, indexes: IndexSet(integer: index))
            send(.sectionUpdate(change))
        }
    }
    
    public func setObjects(_ objects: [Object]) {
        reload(sections: [ArraySection(objects: objects)])
    }

    public func setSections(_ sections: [ArraySection<Object>]) {
        reload(sections: sections)
    }
    
    // MARK: - Search
    
    public func indexPath(of predicate: (Object) -> Bool) -> IndexPath? {
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
 
    public func remove(_ object: Object) {
        if let indexPath = indexPath(of: object) {
            remove(at: indexPath)
        }
    }
    
    /**
     Complexity O(n)
     */
    public func indexPath(of object: Object) -> IndexPath? {
        for index in 0..<sectionsCount {
            if let objectIndex = sections[index].index(of: object) {
                return IndexPath(item: objectIndex, section: index)
            }
        }
        
        return nil
    }
}
