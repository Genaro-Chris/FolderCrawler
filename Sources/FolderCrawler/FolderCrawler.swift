import ArgumentParser
import AsyncAlgorithms
import Foundation
import SignalHandler

@main
struct FolderCrawler: AsyncParsableCommand, @unchecked Sendable {
    static let configuration = CommandConfiguration(
        commandName: "FolderCrawler",
        abstract: "This programs crawler the supplied path and print all files sizes",
        version: "0.1.0")

    @Argument(
        help: ArgumentHelp(
            "Path to crawl",
            discussion: "\t\t  (If no folder is provided, it defaults to the current folder)",
            valueName: "folder"), completion: .directory)
    var path = ""

    @Option(
        name: [.customLong("data-size"), .customLong("ds")],
        help: "Size to display. Available options: b, kb, mb, gb, tb",
        completion: .list(["b", "kb", "mb", "gb", "tb"]))
    var dataSize: Size = .unbounded

    @Option(name: .long, help: "Range of file sizes to include")
    var size: Double = 0

    @Option(name: .customLong("exclude", withSingleDash: false), help: "File or folder to exclude")
    var exclude: String = ""

    @Flag(name: .customLong("subpaths"), help: "Crawl subdirectories too")
    var subDir = false

    mutating func run() async throws {
        Task.detached(priority: .utility) {
            await SignalHandler.start(with: Signals.allCases) { _ in
                print("Quitting")
                Foundation.exit(1)
            }
        }
        let size = size
        var folder = Folder()
        if path.isEmpty {
            path = FileManager.default.currentDirectoryPath
        }

        if !exclude.isEmpty {
            try Folder().changeDirectory(to: exclude)
            exclude = String(URL(fileURLWithPath: exclude).absoluteString.trimmingPrefix("file://"))
        }

        if path != folder.currentPath {
            print("About to change to \(path)")
            try folder.changeDirectory(to: path)
        }

        print(
            "About to search \(folder.currentPath) directory",
            subDir ? "with its subdirectories" : "",
            exclude.isEmpty ? "" : "excluding \(exclude) and all its subdirectories")

        if path == "/" && subDir {
            let (dataSize, exclude) = (dataSize, exclude)
            try await FolderCrawler.forRoot(
                folder: folder, dataSize: dataSize, size: size, exclude: exclude)
            return
        }

        var result: [(Size, String, Double)] = []
        defer {
            print("Size \tPermissions \tFilePath")
            Self.listItems(of: size, dataSize: dataSize, folder: &folder, result: result)
        }

        if path == "/run" && subDir {
            var paths = try folder.crawlFolder()
            if !exclude.isEmpty {
                paths = Self.filterOut(paths, exclude: exclude)
            }
            result = folder.findSize(subpaths: paths, with: size)
            return
        }
        if subDir {
            var paths = try folder.crawlFolder(path: folder.currentPath)
            if !exclude.isEmpty {
                paths = Self.filterOut(paths, exclude: exclude)
            }
            result = folder.findSize(subpaths: paths, with: size)
        } else {
            var paths = try folder.crawlFolder()
            if !exclude.isEmpty {
                paths = Self.filterOut(paths, exclude: exclude)
            }
            result = folder.findSize(subpaths: paths, with: size)
        }
    }


    static func forRoot(
        folder: consuming Folder, dataSize: Size, size: Double, exclude: String
    )
        async throws
    {
        let subpaths: [String] = try folder.crawlRoot()
        let (stream, cont) = AsyncStream<[(Size, String, Double)]>.makeStream()
        async let _ = withTaskGroup(of: Void.self) { group in
            subpaths.forEach { subpath in
                group.addTask {
                    let folder = Folder()
                    try? folder.changeDirectory(to: subpath)
                    let paths =
                        subpath == "/run"
                        ? try? folder.crawlFolder()
                        : try? folder.crawlFolder(path: subpath)
                    guard var paths else {
                        return
                    }
                    if !exclude.isEmpty {
                        paths = filterOut(paths, exclude: exclude)
                    }
                    cont.yield(folder.findSize(subpaths: paths, with: size))
                }
            }
            await group.waitForAll()
            cont.finish()
        }

        await stream.forEach { result in
            listItems(of: size, dataSize: dataSize, folder: &folder, result: result)
        }
        _ = folder
    }

    static func filterOut(_ list: [String], exclude: String) -> [String] {
        list.compactMap {
            return $0.hasPrefix(exclude) || $0 == exclude ? nil : $0
        }
    }

    public static func listItems(
        of size: Double, dataSize: Size, folder: inout Folder, result: [(Size, String, Double)]
    ) {
        if case .unbounded = dataSize {
            folder.listFolderItems(size, of: result)
        } else if (.unbounded == dataSize) && size == 0 {
            folder.listFolderItems(of: result)
        } else {
            folder.listFolderItems(size, of: result) { sizetype, _, _ in
                dataSize == sizetype
            }
        }
    }
}
