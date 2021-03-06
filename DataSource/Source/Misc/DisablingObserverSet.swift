
import Foundation
import Observer

final class DisablingObserverSet<T>: ObserverSet<T> {

    override init() {}

    fileprivate var counterLock: OSSpinLock = OS_SPINLOCK_INIT

    fileprivate var _disabledCounter: Int = 0
    fileprivate var disabledCounter: Int {
        get {
            let value: Int

            OSSpinLockLock(&counterLock)
            value = _disabledCounter
            OSSpinLockUnlock(&counterLock)

            return value
        }

        set {
            OSSpinLockLock(&counterLock)
            _disabledCounter = newValue
            OSSpinLockUnlock(&counterLock)
        }
    }

    var enabled: Bool {
        return disabledCounter == 0
    }

    func enable() {
        precondition(disabledCounter > 0)

        disabledCounter -= 1
    }

    func disable() {
        precondition(disabledCounter >= 0)

        disabledCounter += 1
    }

    override func send(_ value: T) {
        if enabled {
            super.send(value)
        }
    }
}
