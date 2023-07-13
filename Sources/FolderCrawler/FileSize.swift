import ArgumentParser
import Foundation

/// A computer file data size representation
@frozen
public enum Size: String, ExpressibleByArgument {
    case B
    case KB
    case MB
    case GB
    case TB
    case PB
    case EB
    case unbounded
}

extension Size: CustomStringConvertible {
    public var description: String {
        let string: String
        switch self {
            case .KB: string = "kb"
            case .GB: string = "gb"
            case .MB: string = "mb"
            case .TB: string = "tb"
            case .PB: string = "pb"
            case .B: string = "b"
            case .EB: string = "eb"
            case .unbounded: string = "unbounded"
        }
        return string
    }
}

extension Size: Sendable {
    /// Initializes according to the argument passed to the appropriate ``Size`` instance otherwise fails and return nil
    /// - Parameter rawValue: the file size
    public init?(_ rawValue: Double) {
        let pb_limit: Double = (1024 * 1024 * 1024) * 1024 * 1_073_741_824
        switch rawValue {
            case 0 ..< 1024: self = .B
            case 1024 ..< 1_048_576: self = .KB
            case 1_048_576 ..< 1024 * 1_048_576: self = .MB
            case 1_073_741_824 ..< 1024 * 1_073_741_824: self = .GB
            case 1024 * 1_073_741_824 ..< 1024 * 1024 * 1_073_741_824: self = .TB
            case 1024 * 1024 * 1_073_741_824 ..< 1024 * 1024 * 1024 * 1_073_741_824: self = .PB
            case (1024 * 1024 * 1024) * 1_073_741_824 ..< pb_limit: self = .EB
            default: return nil
        }
    }
}

extension Size {
    /// First converts the argument passed to a ``Size`` instance, then returns the file size as an double value otherwise fails and returns nil
    /// - Parameter value: Argument value to convert to an ``Size`` instance
    /// - Returns: File size value of the appropriate ``Size`` case as a double value or nil if anything goes wrong
    public func sizer(_ value: Double) -> Double? {
        guard let size = Size.init(value) else {
            return nil
        }

        switch size {
            case .B: return value
            case .KB: return value / 1024
            case .MB: return value / (1024 * 1024)
            case .GB: return value / (1024 * 1024 * 1024)
            case .TB: return value / (1024 * 1024 * 1024 * 1024)
            case .PB: return value / (1024 * 1024 * 1024 * 1024 * 1024)
            case .EB: return value / (1024 * 1024 * 1024 * 1024 * 1024 * 1024)
            default: return nil
        }
    }
}

extension Size: RawRepresentable {
    ///   Initializes this type to the appropriate case from the argument passed otherwise fails and returns nil
    /// - Parameter rawValue: string value
    public init?(rawValue: String) {
        switch rawValue {
            case "B", "b": self = .B
            case "KB", "kb": self = .KB
            case "MB", "mb": self = .MB
            case "GB", "gb": self = .GB
            case "TB", "tb": self = .TB
            case "PB", "pb": self = .PB
            case "EB", "eb": self = .EB
            default: return nil
        }
    }
}
