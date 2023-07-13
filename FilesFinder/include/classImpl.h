#include <iostream>
#include <vector>
#include <stdlib.h>
#include <array>
#include <bridging>

#ifndef Header_M
#define Header_M

using namespace std;


struct FilesFinders
{
private:
    vector<string> paths;
    string root;

public:
    void empty();
    FilesFinders() = default; 
    ~FilesFinders();
    void append(string path);
    string getRoot() const SWIFT_COMPUTED_PROPERTY;
    void setRoot(string root) SWIFT_COMPUTED_PROPERTY;
    vector<string> getPaths() const SWIFT_COMPUTED_PROPERTY;
};

auto getPathsRecursively(string from) -> FilesFinders;
auto getPaths(string from) -> FilesFinders;

auto getFileSize(string path) -> unsigned long;

auto getFilePermission(string path) -> int;

#endif