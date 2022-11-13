import Foundation

internal final class Folder: @unchecked Sendable {
    /// Errors associated with crawling directory
    enum FileError : Error, CustomStringConvertible {
        var description: String {
            switch self {
                case .fileNotFound: return "Folder is invalid or missing"
                case .permissionError: return "Invalid permissions to enumerate files of this folder"
                case .notAFolder: return "The specified path is not a directory"
            }
        }
        /// Permission file error
        case permissionError
        /// Missing file
        case fileNotFound
        /// Not a directory
        case notAFolder
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
    
    let fileManager = FileManager()

    /// the current working directory
    var currentPath : String {
        fileManager.currentDirectoryPath
    }  

    /// changes the directory
    /// - Parameter to:  the path to change to
    /// - Throws: ``Folder.FileError``
    func changeDirectory(to path: String) throws {
        var isDir: ObjCBool = false
        let fileExists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        switch (fileExists, Bool(String(describing:isDir))) {
            case (false, false): throw FileError.fileNotFound
            case (true, false): throw FileError.notAFolder
            case (false, true): throw FileError.fileNotFound
            case (true, true): break
            default: break
        }
        guard fileManager.changeCurrentDirectoryPath(path) else {
            throw FileError.permissionError
        }
    }
    
    /// Crawls the current path non recursively but if anything goes wrong it throws
    /// - Throws: ``Folder.FileError`` 
    /// - Returns: An array of paths as String
    func crawlFolder() throws -> [String] {
        let paths = try? fileManager.contentsOfDirectory(atPath: currentPath)
        guard let paths, !paths.isEmpty else {
            throw FileError.permissionError
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
            throw FileError.permissionError
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
            throw FileError.permissionError
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
        var result = [(Size, String, Double)]()
        for subpath in subpaths {
            let attributes = try? fileManager.attributesOfItem(atPath: subpath)
            if let filesize = attributes?[.size] as? Double,
            let size = Size.init(filesize), 
            let sizeDesc = size.sizer(filesize)?.rounded(.toNearestOrAwayFromZero) {  
                result.append((size,"\(sizeDesc)\(size)\t\t\(subpath)",sizeDesc))
            }
        }
        return result
    }


}
                
extension FileManager : @unchecked Sendable {} 
