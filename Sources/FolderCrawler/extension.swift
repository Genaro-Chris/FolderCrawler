@_implementationOnly import FilesFinder
import Foundation

extension FilesFinders: @unchecked Sendable {}

extension AsyncSequence {
    func forEach(body: (Element) throws -> Void) async rethrows {
        for try await item in self {
            try body(item)
        }
    }
}

