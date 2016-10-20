
import Foundation

final class MappingSection<RawObject, Object>: Section<Object> {
    
    let origin: DataSource<RawObject>
    let map: (RawObject) -> Object
    
    var originIndex: Int
    
    private var _objects: [Object?] = []
    
    // MARK: - Init
    
    init(origin: DataSource<RawObject>, originIndex: Int, map: @escaping (RawObject) -> Object) {
        self.origin = origin
        self.originIndex = originIndex
        self.map = map
        
        _objects = Array(repeating: nil, count: origin.numberOfObjects(inSection: originIndex))
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
        return (0..<numberOfObjects).map { object(at: $0) }
    }
    
    func object(at index: Int) -> Object {
        if let object = _objects[index] {
            return object
        }
        
        let object = map(origin.object(at: IndexPath(item: index, section: originIndex)))
        _objects[index] = object
        
        return object
    }

    // MARK: - Mutation
    
    func insert(_ object: Object?, at index: Int) {
        _objects.insert(object, at: index)
    }

    @discardableResult
    func remove(at index: Int) -> Object? {
        return _objects.remove(at: index)
    }
    
    func invalidate(at index: Int) {
        _objects[index] = nil
    }
    
    func invalidateAll() {
        _objects = Array(repeating: nil, count: origin.numberOfObjects(inSection: originIndex))
    }
}
