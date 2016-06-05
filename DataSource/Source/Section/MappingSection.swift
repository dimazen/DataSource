
import Foundation

final class MappingSection<RawObject, Object>: Section<Object> {
    
    let origin: DataSource<RawObject>
    let map: RawObject -> Object
    
    var originIndex: Int
    
    private var _objects: [Object?] = []
    
    // MARK: - Init
    
    init(origin: DataSource<RawObject>, originIndex: Int, map: RawObject -> Object) {
        self.origin = origin
        self.originIndex = originIndex
        self.map = map
        
        _objects = Array(count: origin.numberOfObjectsInSection(originIndex), repeatedValue: nil)
    }
    
    // MARK: - UserInfo
    
    private var _name: String?
    override var name: String? {
        get {
            return _name ?? origin[originIndex].name
        }
        
        set {
            _name = newValue
        }
    }
    
    private var _userInfo: [String: AnyObject]?
    override var userInfo: [String: AnyObject]? {
        get {
            return _userInfo ?? origin[originIndex].userInfo
        }
        
        set {
            _userInfo = newValue
        }
    }

    // MARK: - Access
    
    override var numberOfObjects: Int {
        return _objects.count
    }
    
    override var objects: [Object] {
        return (0..<numberOfObjects).map { objectAtIndex($0) }
    }
    
    func objectAtIndex(index: Int) -> Object {
        if let object = _objects[index] {
            return object
        }
        
        let object = map(origin.objectAtIndexPath(NSIndexPath(forItem: index, inSection: originIndex)))
        _objects[index] = object
        
        return object
    }

    // MARK: - Mutation
    
    func insert(object: Object?, atIndex index: Int) {
        _objects.insert(object, atIndex: index)
    }

    func removeObjectAtIndex(index: Int) -> Object? {
        return _objects.removeAtIndex(index)
    }
    
    func invalidateObjectAtIndex(index: Int) {
        _objects[index] = nil
    }
    
    func invalidateObjects() {
        _objects = Array(count: origin.numberOfObjectsInSection(originIndex), repeatedValue: nil)
    }
}
