import SwiftUI
import Combine

/// A drop-in, robust state property wrapper for standalone macOS builds
/// that does not depend on the SwiftUIMacros compiler plugin.
@propertyWrapper
@MainActor
public struct UIState<Value>: DynamicProperty {
    @StateObject private var storage: Storage
    
    public init(wrappedValue: Value) {
        _storage = StateObject(wrappedValue: Storage(wrappedValue))
    }
    
    public init(initialValue: Value) {
        _storage = StateObject(wrappedValue: Storage(initialValue))
    }
    
    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: { storage.value = $0 }
        )
    }
    
    private final class Storage: ObservableObject, @unchecked Sendable {
        @Published var value: Value
        init(_ value: Value) {
            self.value = value
        }
    }
}
