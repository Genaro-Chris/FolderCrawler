@_implementationOnly import FilesFinder
import Foundation

package struct Folder: ~Copyable {
    /// Errors associated with crawling directory
    enum FileError: Error, CustomStringConvertible {
        var description: String {
            switch self {
                case let .fileNotFound(pathname): return "Folder \(pathname) is invalid or missing"
                case let .permissionError(pathname):
                    return "Invalid permissions to enumerate files of this folder \(pathname)"
                case let .notAFolder(pathname):
                    return "The specified path \(pathname) is not a directory"
            }
        }
        /// Permission file error
        case permissionError(at: String)
        /// Missing file
        case fileNotFound(at: String)
        /// Not a directory
        case notAFolder(at: String)
    }

    /// File count of the file print out
    private var fileCount = 0

    /// increments the ``fileCount`` property
    private mutating func add() {
        fileCount += 1
    }

    deinit {
        if fileCount > 0 {
            print("Scanned \(fileCount) files in total")
        }
    }

    //let fileManager = FileManager.default
    /// the current working directory
    var currentPath: String {
        FileManager.default.self.currentDirectoryPath
    }

    /// changes the directory
    /// - Parameter to:  the path to change to
    /// - Throws: ``Folder.FileError``
    func changeDirectory(to path: String) throws {
        var isDir: ObjCBool = false
        let fileExists = FileManager.default.self.fileExists(atPath: path, isDirectory: &isDir)
        switch (fileExists, Bool(String(describing: isDir))) {
            case (false, false): throw FileError.fileNotFound(at: path)
            case (true, false): throw FileError.notAFolder(at: path)
            case (false, true): throw FileError.fileNotFound(at: path)
            case (true, true): break
            default: break
        }
        guard FileManager.default.self.changeCurrentDirectoryPath(path) else {
            throw FileError.permissionError(at: path)
        }
    }


    /// Crawls the current path non recursively but if anything goes wrong it throws
    /// - Throws: ``Folder.FileError``
    /// - Returns: An array of paths as String
    func crawlFolder() throws -> [String] {
        let folder = getPaths(std.string(stringLiteral: self.currentPath))
        guard !folder.paths.isEmpty else {
            throw FileError.permissionError(at: currentPath)
        }
        let paths = folder.paths.map {
            String($0)
        }
        return paths
    }

    /// Crawls the argument passed recursively but if anything goes wrong it throws
    ///
    /// - Throws: ``Folder.FileError``
    /// - Parameter path: The path to be crawled
    /// - Returns: Array of paths found
    func crawlFolder(path: String) throws -> [String] {
        let folder = getPathsRecursively(std.string(stringLiteral: path))
        guard !folder.paths.isEmpty else {
            throw FileError.permissionError(at: path)
        }
        let paths = folder.paths.map {
            String($0)
        }
        return paths
    }


    /// Crawls the root path non-recursively but anything goes wrong it throws
    /// - Throws: ``Folder.FileError``
    ///
    /// - Returns: Array of paths found
    func crawlRoot() throws -> [String] {
        let folder = getPaths("/")
        return folder.paths.map {
            String($0)
        }
    }

    /// Prints out the files with their respective sizes
    ///
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    ///   - with: a closure for filtering the array
    mutating func listFolderItems(
        _ from: Double, of: [(Size, String, Double)], with: @escaping (Size, String, Double) -> Bool
    ) {
        let of = of.filter(with)
        for (_, msg, _) in of {
            self.add()
            print(msg)
        }
    }

    /// Prints out the files with their respectives sizes
    ///
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    mutating func listFolderItems(_ from: Double, of: [(Size, String, Double)]) {
        for (_, msg, _) in of {
            self.add()
            print(msg)
        }
    }

    /// Prints out the files with their respectives sizes
    ///
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    mutating func listFolderItems(of: [(Size, String, Double)]) {
        for (_, msg, _) in of {
            add()
            print(msg)
        }
    }

    func findSize(subpaths: [String], with: Double) -> [(Size, String, Double)] {
        return with != 0.0
            ? subpaths.compactMap { subpath in
                let filesize = Double(getFileSize(std.string(stringLiteral: subpath)))
                let perms = Int(getFilePermission(std.string(stringLiteral: subpath)))
                let size = Size.init(filesize)!
                let sizeDesc = size.sizer(filesize)!.rounded(.toNearestOrAwayFromZero)
                if with >= sizeDesc {
                    return (
                        size,
                        "\(sizeDesc)\(size)\t \(changePermissions(perms))  \t \(subpath)",
                        sizeDesc
                    )
                }
                return nil
            }
            : subpaths.map { subpath in
                let filesize = Double(getFileSize(std.string(stringLiteral: subpath)))
                let perms = Int(getFilePermission(std.string(stringLiteral: subpath)))
                let size = Size.init(filesize) ?? .unbounded
                let sizeDesc = size.sizer(filesize)!.rounded(.toNearestOrAwayFromZero)
                return (
                    size,
                    "\(sizeDesc)\(size)\t \(changePermissions(perms))  \t \(subpath)",
                    sizeDesc
                )
            }
    }

    /// Changes permissions from its POSIX bits into human-readable string
    ///
    /// - Parameter perms: POSIX bits
    /// - Returns: Converted string
    func changePermissions(_ perms: Int) -> String {
        let perms = UInt(
            String(perms, radix: 8).reduce("") {
                $0 + String($1)
            })
        guard let perms, perms > 99 else {
            return "---------"
        }
        var permToString = ""
        let permValue = [(4, "r"), (2, "w"), (1, "x")]
        for octal in String(perms) {
            var intOctal = Int(String(octal))!
            for (intValue, strValue) in permValue {
                if intOctal >= intValue {
                    permToString += strValue
                    intOctal -= intValue
                } else {
                    permToString += "-"
                }
            }
        }
        return permToString
    }
}

extension FileManager: @unchecked Sendable {}
