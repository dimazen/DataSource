
import Foundation

public protocol ObjectMappable {
    
    var cellIdentifier: String { get }
    
    func supports(_ object: Any) -> Bool
    
    func map(object: Any, toCell cell: Any, at: IndexPath)
}

final public class ObjectConsumingMapper<Object, Cell>: ObjectMappable {
    
    private let map: (Object, Cell, IndexPath) -> Void
    
    public init(map: @escaping (Object, Cell, IndexPath) -> Void) {
        self.map = map
    }
    
    public var cellIdentifier: String {
        return String(describing: Cell.self)
    }
    
    public func supports(_ object: Any) -> Bool {
        return object is Object
    }
    
    public func map(object: Any, toCell cell: Any, at indexPath: IndexPath) {
        if let object = object as? Object, let cell = cell as? Cell {
            map(object, cell, indexPath)
        }
    }
}

public protocol ObjectConsuming {
    
    associatedtype Object
    
    func apply(object: Object)
}

extension ObjectConsumingMapper where Cell: ObjectConsuming, Cell.Object == Object {
    
    convenience public init() {
        self.init { object, consumer, _ in
            consumer.apply(object: object)
        }
    }
}
