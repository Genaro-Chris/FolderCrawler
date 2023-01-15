import Foundation

internal final class Folder: @unchecked Sendable {
    /// Errors associated with crawling directory
    enum FileError : Error, CustomStringConvertible {
        var description: String {
            switch self {
                case let .fileNotFound(pathname): return "Folder \(pathname) is invalid or missing"
                case let .permissionError(pathname): return "Invalid permissions to enumerate files of this folder \(pathname)"
                case let .notAFolder(pathname): return "The specified path \(pathname) is not a directory"
            }
        }
        /// Permission file error
        case permissionError(at:String)
        /// Missing file
        case fileNotFound(at:String)
        /// Not a directory
        case notAFolder(at:String)
    }
    
    /// File count of the file print out
    private var fileCount = 0

    /// increments the ``fileCount`` property
    private func add() {
        fileCount += 1
    }

    deinit {
        if fileCount > 0 {
            print("Scanned \(fileCount) files in total")
        }
    }
    
    let fileManager = FileManager.default

    /// the current working directory
    var currentPath: String {
        fileManager.currentDirectoryPath
    }  

    /// changes the directory
    /// - Parameter to:  the path to change to
    /// - Throws: ``Folder.FileError``
    func changeDirectory(to path: String) throws {
        var isDir: ObjCBool = false
        let fileExists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        switch (fileExists, Bool(String(describing:isDir))) {
            case (false, false): throw FileError.fileNotFound(at:path)
            case (true, false): throw FileError.notAFolder(at: path)
            case (false, true): throw FileError.fileNotFound(at:path)
            case (true, true): break
            default: break
        }
        guard fileManager.changeCurrentDirectoryPath(path) else {
            throw FileError.permissionError(at: path)
        }
    }
    
    /// Crawls the current path non recursively but if anything goes wrong it throws
    /// - Throws: ``Folder.FileError`` 
    /// - Returns: An array of paths as String
    func crawlFolder() throws -> [String] {
        let paths = try? fileManager.contentsOfDirectory(atPath: currentPath)
        guard let paths, !paths.isEmpty else {
            throw FileError.permissionError(at: currentPath)
        }
        return paths        
    }

    /// Crawls the argument passed recursively but if anything goes wrong it throws
    /// 
    /// - Throws: ``Folder.FileError``
    /// - Parameter path: The path to be crawled
    /// - Returns: Array of paths found
    func crawlFolder(path: String) throws -> [String] {  
        let paths = try? fileManager.subpathsOfDirectory(atPath: path)
        guard let paths else {
            throw FileError.permissionError(at: path)
        } 
        return paths.map {
            path + "/" + $0
        }
       
    }
   
    /// Crawls the root path non-recursively but anything goes wrong it throws
    /// - Throws: ``Folder.FileError``
    /// 
    /// - Returns: Array of paths found 
    func crawlRoot() throws -> [String] {
        let paths = try? fileManager.contentsOfDirectory(atPath: "/")
        guard let paths, !paths.isEmpty else {
            throw FileError.permissionError(at: "/")
        }
        return paths.map {
            "/" + $0
        }
    }

    /// Prints out the files with their respective sizes
    /// 
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    ///   - with: a closure for filtering the array
    func listFolderItems(_ from: Double, of: [(Size, String, Double)], with: @escaping (Size, String, Double) -> Bool) {
        let result = of.filter(with).filter { _, _, size in
            size >= from 
        }
        for msg in result {
            add()
            print(msg.1)
        }
    }
    
    /// Prints out the files with their respectives sizes
    /// 
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    func listFolderItems(_ from: Double, of:[(Size, String, Double)]) {
        let of = of.filter { _,_, size in
            size >= from
        }
        for msg in of {
            add()
            print(msg.1)
        }
    }

    /// Checks for file size
    /// 
    /// - Parameter subpaths: array of filepaths
    /// - Returns: array of tuple containing the size, file name and the numerical file size
    func findSize(subpaths: [String]) -> [(Size, String, Double)] {
        subpaths.compactMap { subpath in
            let attributes = try? fileManager.attributesOfItem(atPath: subpath)
            if let filesize = attributes?[.size] as? Double,
            let size = Size.init(filesize), 
            let perms = attributes?[.posixPermissions] as? UInt,
            let sizeDesc = size.sizer(filesize)?.rounded(.toNearestOrAwayFromZero) {  
                return (size,"\(sizeDesc)\(size)\t \(changePermissions(perms))  \t \(subpath)",sizeDesc)
            }
        }
        return nil
    }

    /// Changes permissions from its POSIX bits into human-readable string
    ///
    /// - Parameter perms: POSIX bits
    /// - Returns: Converted string
    func changePermissions(_ perms: Int) -> String {
        let perms = UInt(String(perms, radix:8).reduce("") { 
            $0 + String($1)
         })
        guard let perms, perms > 99 else { 
            return "---------" 
        }
        var permToString = ""
        let permValue = [(4,"r"),(2,"w"),(1,"x")]
        for octal in String(perms) {
            var intOctal = Int(String(octal))!
            permValue.forEach { intValue, strValue in 
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


         
extension FileManager : @unchecked Sendable {} 
