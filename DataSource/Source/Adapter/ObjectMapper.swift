
import Foundation

public protocol ObjectMappable {
    
    var cellIdentifier: String { get }
    
    func supportsObject(object: Any) -> Bool
    
    func mapObject(object: Any, toCell cell: Any, atIndexPath: NSIndexPath)
}

public class ObjectConsumingMapper<Object, Cell>: ObjectMappable {
    
    private let map: (Object, Cell, NSIndexPath) -> Void
    
    public init(map: (Object, Cell, NSIndexPath) -> Void) {
        self.map = map
    }
    
    public var cellIdentifier: String {
        return String(Cell.self)
    }
    
    public func supportsObject(object: Any) -> Bool {
        return object is Object
    }
    
    public func mapObject(object: Any, toCell cell: Any, atIndexPath indexPath: NSIndexPath) {
        if let object = object as? Object, cell = cell as? Cell {
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
            consumer.apply(object)
        }
    }
}