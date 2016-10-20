
import Foundation

open class ArraySection<Object>: Section<Object> {
    
    private var _objects: [Object]
    
    // MARK: - Init
    
    open init(name: String, objects: [Object]) {
        _objects = objects
        super.init(name: name, userInfo: nil)
    }
    
    open init(objects: [Object]) {
        _objects = objects
        
        super.init()
    }
    
    // MARK: - Section
    
    func object(at index: Int) -> Object {
        return _objects[index]
    }
    
    override open var objects: [Object] {
        return _objects
    }
    
    override open var numberOfObjects: Int {
        return _objects.count
    }
    
    open internal(set) subscript(index: Int) -> Object {
        get {
            return _objects[index]
        }
        
        set {
            _objects[index] = newValue
        }
    }
    
    // MARK: - Mutation
    
    func insert(_ object: Object, at index: Int) {
        _objects.insert(object, at: index)
    }
    
    func remove(at index: Int) -> Object {
        return _objects.remove(at: index)
    }
}

extension ArraySection where Object: Equatable {
    
    func index(of object: Object) -> Int? {
        return _objects.index(of: object)
    }
}
