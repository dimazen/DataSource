
import Foundation

public class ArraySection<Object>: Section<Object> {
    
    private var _objects: [Object]
    
    // MARK: - Init
    
    public init(name: String, objects: [Object]) {
        _objects = objects
        super.init(name: name, userInfo: nil)
    }
    
    public init(objects: [Object]) {
        _objects = objects
        
        super.init()
    }
    
    // MARK: - Section
    
    func objectAtIndex(index: Int) -> Object {
        return _objects[index]
    }
    
    override public var objects: [Object] {
        return _objects
    }
    
    override public var numberOfObjects: Int {
        return _objects.count
    }
    
    subscript(index: Int) -> Object {
        get {
            return _objects[index]
        }
        
        set {
            _objects[index] = newValue
        }
    }
    
    // MARK: - Mutation
    
    func insert(object: Object, atIndex index: Int) {
        _objects.insert(object, atIndex: index)
    }
    
    func removeAtIndex(index: Int) -> Object {
        return _objects.removeAtIndex(index)
    }
}

extension ArraySection where Object: Equatable {
    
    func indexOf(object: Object) -> Int? {
        return _objects.indexOf(object)
    }
}