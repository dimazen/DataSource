
import Foundation
import Observer

final public class MappingDataSource<RawObject, Object>: DataSource<Object> {
    
    public typealias Map = (RawObject) -> Object
    fileprivate let map: Map
    
    fileprivate var disposable: Disposable?
    public let origin: DataSource<RawObject>
    
    // MARK: - Init
    
    deinit {
        disposable?.dispose()
    }
    
    public init(origin: DataSource<RawObject>, map: @escaping Map) {
        self.origin = origin
        self.map = map
        
        super.init()
        
        disposable = origin.observe { [unowned self] event in
            self.handleEvent(event)
        }
    }
    
    // MARK: - Sections
    
    fileprivate var _sections: [MappingSection<RawObject, Object>] = []
    fileprivate var sections: [MappingSection<RawObject, Object>] {
        get {
            if invalidated {
                reload()
            } else {
                reindexSectionsIfNeeded()
            }
            
            return _sections
        }
        
        set {
            _sections = sections
        }
    }
    
    // MARK: - Access

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
    
    // MARK: - Reload
    
    fileprivate var invalidated = true
    override public func invalidate() {
        invalidated = true
        
        send(.invalidate)
    }
    
    // to prevent double reloading when MappingDataSource cause Origin to reload
    fileprivate var reloading = true
    
    override public func reload() {
        reloading = true
        
        _sections = (0..<origin.sectionsCount).map { return MappingSection(origin: self.origin, originIndex: $0, map: self.map) }

        invalidated = false
        reloading = false
        sectionsIndexInvalid = false

        send(.reload)
    }
    
    public func reloadObjectAtIndexPath(_ indexPath: IndexPath) {
        let section = sections[(indexPath as NSIndexPath).section]
        section.invalidateObjectAtIndex((indexPath as NSIndexPath).item)
        
        let change = ObjectChange(type: .update, source: indexPath)
        send(.objectUpdate(change))
    }
    
    fileprivate var sectionsIndexInvalid = true
    
    fileprivate func setNeedsSectionReindex() {
        sectionsIndexInvalid = true
    }
    
    fileprivate func reindexSectionsIfNeeded() {
        if sectionsIndexInvalid {
            for (index, section) in _sections.enumerated() {
                section.originIndex = index
            }
        }
        
        sectionsIndexInvalid = false
    }
    
    // MARK: - Events Handling
    
    fileprivate func handleEvent(_ event: Event) {
        switch event {
        case .invalidate:
            invalidate()
            
        case .reload where reloading:
            break
            
        case .reload:
            reload()
            
        case .sectionUpdate(let change):
            setNeedsSectionReindex()
            applySectionChange(change)
            
            send(event)
            
        case .objectUpdate(let change):
            applyObjectChange(change)
            
            send(event)
            
        case .willBeginUpdate, .didEndUpdate:
            send(event)
        }
    }
    
    fileprivate func applyObjectChange(_ change: ObjectChange) {
        switch change.type {
        case .insert:
            sections[change.target.section].insert(nil, atIndex: change.target.item)
            
        case .delete:
            sections[change.source.section].removeObjectAtIndex(change.source.item)
            
        case .move:
            let object = sections[change.source.section].removeObjectAtIndex(change.source.item)
            sections[change.target.section].insert(object, atIndex: change.target.item)
            
        case .update:
            sections[change.source.section].invalidateObjectAtIndex(change.source.item)
        }
    }
    
    fileprivate func applySectionChange(_ change: SectionChange) {
        switch change.type {
        case .insert:
            for index in change.indexes {
                sections.insert(MappingSection(origin: origin, originIndex: index, map: map), at: index)
            }
        
        case .delete:
            for index in change.indexes {
                sections.remove(at: index)
            }
            
        case .move:
            abort()
            
        case .update:
            for index in change.indexes {
                sections[index].invalidateObjects()
            }
        }
    }
    
    // MARK: - Search
    
    public func indexPathOf(_ predicate: (Object) -> Bool) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for objectIndex in 0..<numberOfObjectsInSection(sectionIndex) {
                if predicate(section.objectAtIndex(objectIndex)) {
                    return IndexPath(item: objectIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
}
