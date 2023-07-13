#include <classImpl.h>
#include <iostream>
#include <fstream>
#include <system_error>
#include <vector>
#include <stdlib.h>
#include <filesystem>
#include <string.h>

using namespace std;
using namespace filesystem;

void FilesFinders::append(string path)
{
    this->paths.push_back(path);
}

void FilesFinders::empty()
{
    this->paths.clear();
}

FilesFinders::~FilesFinders()
{
    this->empty();
}

auto FilesFinders::getRoot() const -> string
{
    return this->root;
}

void FilesFinders::setRoot(string root)
{
    this->root = root;
}

auto FilesFinders::getPaths() const -> vector<string>
{
    return std::move(this->paths);
}

auto getPaths(string from) -> FilesFinders
{
    FilesFinders folder;
    try
    {
        auto root_path = filesystem::path(from);
        folder.setRoot(from);
        error_code ec;
        auto folder_iterator = directory_iterator(root_path, ec);
        for (auto &dir_entry : folder_iterator)
        {
            if (ec)
            {
                continue;
            }
            folder.append(dir_entry.path());
        }
        return folder;
    }
    catch (filesystem_error &e)
    {
        folder.empty();
        return folder;
    }
}

auto getPathsRecursively(string from) -> FilesFinders
{
    FilesFinders folder;
    try
    {
        auto root_path = filesystem::path(from);
        folder.setRoot(from);
        error_code ec;
        auto folder_iterator = recursive_directory_iterator(root_path, ec);
        auto options = folder_iterator.recursion_pending();
        for (auto &dir_entry : folder_iterator)
        {
            if (ec)
            {
                continue;
            }
            folder.append(dir_entry.path());
        }
        return folder;
    }
    catch (filesystem_error &e)
    {
        folder.empty();
        return folder;
    }
}

auto getFileSize(string path_name) -> unsigned long
{
    try // throws error if the path is a directory not a file
    {
        auto path = filesystem::path(path_name);
        return file_size(path);
    }
    catch (filesystem_error &e)
    {
        return 1024 * 4; // returns 4kb as size
    }
}

auto getFilePermission(string path_name) -> int
{
    auto path = filesystem::path(path_name);
    try
    {
        auto filestatus = status(path);
        return static_cast<int>(filestatus.permissions());
    }
    catch (filesystem_error)
    {
        return static_cast<int>(perms::none);
    }
}
