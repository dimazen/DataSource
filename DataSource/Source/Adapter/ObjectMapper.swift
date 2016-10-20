
import Foundation

public protocol ObjectMappable {
    
    var cellIdentifier: String { get }
    
    func supportsObject(_ object: Any) -> Bool
    
    func mapObject(_ object: Any, toCell cell: Any, atIndexPath: IndexPath)
}

open class ObjectConsumingMapper<Object, Cell>: ObjectMappable {
    
    fileprivate let map: (Object, Cell, IndexPath) -> Void
    
    public init(map: @escaping (Object, Cell, IndexPath) -> Void) {
        self.map = map
    }
    
    open var cellIdentifier: String {
        return String(describing: Cell.self)
    }
    
    open func supportsObject(_ object: Any) -> Bool {
        return object is Object
    }
    
    open func mapObject(_ object: Any, toCell cell: Any, atIndexPath indexPath: IndexPath) {
        if let object = object as? Object, let cell = cell as? Cell {
            map(object, cell, indexPath)
        }
    }
}

public protocol ObjectConsuming {
    
    associatedtype Object
    
    func apply(_ object: Object)
}

extension ObjectConsumingMapper where Cell: ObjectConsuming, Cell.Object == Object {
    
    convenience public init() {
        self.init { object, consumer, _ in
            consumer.apply(object)
        }
    }
}
