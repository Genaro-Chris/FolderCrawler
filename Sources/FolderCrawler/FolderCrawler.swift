import ArgumentParser
import SignalHandler
import Foundation



@main
struct FolderCrawler : AsyncParsableCommand, @unchecked Sendable {
    static let configuration = CommandConfiguration(commandName: "FolderCrawler", abstract: "This programs crawler the supplied path and print all files sizes", version: "0.1.0")

    @Argument(help: ArgumentHelp("Path to crawl", discussion: "\t\t  (If no folder is provided, it defaults to the current folder)", valueName: "folder"), completion: .directory)
    var path = ""

    @Option(name: [.customLong("data-size"), .customLong("ds")], help: "Size to display. Available options: b, kb, mb, gb, tb", completion: .list(["b", "kb", "mb", "gb", "tb"]))
    var dataSize : Size = .unbounded

    @Option(name: .long ,help: "Range of file sizes to include")
    var size: Double = 0

    @Option(name: .customLong("exclude", withSingleDash: false), help: "File or folder to exclude")
    var exclude: String = ""


    @Flag(name: .customLong("subpaths"), help: "Crawl subdirectories too")
    var subDir = false

    mutating func run() async throws {
        Task.detached(priority: .utility) { await SignalHandler.default.start() }
        let (size, dataSize) = (size, dataSize)
        let folder = Folder()
        if path.isEmpty {
            path = FileManager.default.currentDirectoryPath
        }
        if path != folder.currentPath {
            print("About to change to \(path)")
            try folder.changeDirectory(to: path)
        }
        if !exclude.isEmpty {
            do {
                try Folder().changeDirectory(to: exclude)
            } catch {
                FolderCrawler.exit(withError: error)
            }
            
        }
        print("About to search \(folder.currentPath) directory", subDir ? "with its subdirectories" : "", exclude.isEmpty ? "" : "excluding \(exclude) and all its subdirectories")

        if (path == "/" && subDir) {   
            try await FolderCrawler.forRoot(folder: folder, dataSize: dataSize, size: size, exclude: exclude)
            return  
        }
    
        if (path == "/run" && subDir) {
            var paths = try folder.crawlFolder()
            if !exclude.isEmpty {
                paths.removeAll {
                    $0.starts(with: URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")) 
                }
            }
            let results = folder.findSize(subpaths: paths)
            Self.listItems(of: size, dataSize: dataSize, folder: folder, result: results)
            return
        }
        if subDir {
            var paths = try folder.crawlFolder(path: folder.currentPath)
            if !exclude.isEmpty {
                paths.removeAll {
                    let fullpath = URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")
                    return $0.starts(with: URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")) || $0 == fullpath
                }
            }
            Self.listItems(of: size, dataSize: dataSize, folder: folder, result: folder.findSize(subpaths: paths))
        } else {
            var paths = try folder.crawlFolder()
            if !exclude.isEmpty {
                paths.removeAll {
                    let fullpath = URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")
                    return $0.starts(with: URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")) || $0 == fullpath
                }
            }
            Self.listItems(of: size, dataSize: dataSize, folder: folder, result: folder.findSize(subpaths: paths))
        }
    } 
    
    @inlinable
    nonisolated
    static func forRoot(folder: Folder, dataSize: Size, size: Double, exclude: String) async throws {
        let subpaths = try folder.crawlRoot()
        await withTaskGroup(of: [(Size,String,Double)].self) { group in 
            for subpath in subpaths {
                if subpath == "/run" {
                    group.addTask { 
                        let fold = Folder()
                        try? fold.changeDirectory(to: subpath)
                        let runpath = try? fold.crawlFolder().map { subpath + "/" + $0 }
                        guard var runpath, !runpath.isEmpty else {
                            return []
                        }   
                        if !exclude.isEmpty {
                            runpath.removeAll {
                                let fullpath = URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")
                                return $0.starts(with: URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")) || $0 == fullpath
                            }
                            return fold.findSize(subpaths: runpath)
                        }
                        return fold.findSize(subpaths: runpath)
                    }
                } else {
                    group.addTask {
                        let fold = Folder()
                        try? fold.changeDirectory(to: subpath)
                        let paths = try? fold.crawlFolder(path: subpath)
                        guard var paths, !paths.isEmpty else {
                            return []
                        }  
                        if !exclude.isEmpty {
                            paths.removeAll {
                                let fullpath = URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")
                                return $0.starts(with: URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://")) || $0 == fullpath
                            }
                            return fold.findSize(subpaths: paths)
                        }
                        return fold.findSize(subpaths: paths)
                    }
                }
            }
            await group.forEach { result in
                listItems(of: size, dataSize: dataSize, folder: folder, result: result)
            }
        }
    }

    static 
    func listItems(of size: Double, dataSize: Size, folder: Folder, result: [(Size,String,Double)])  {
        if dataSize != .unbounded  {
            folder.listFolderItems(size,of: result) { sizetype, _, _  in
                dataSize == sizetype
            } 
        } else { 
            folder.listFolderItems(size,of: result)
        }   
    }

}                             


extension AsyncSequence {
    func forEach(body: (Element) throws -> Void) async rethrows {
        for try await element in self {
            try body(element)
        }
    }
}