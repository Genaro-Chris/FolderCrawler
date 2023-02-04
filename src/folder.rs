use crate::{FileError, FileSize};

use std::{
    fs::{self, Permissions},
    os::unix::prelude::PermissionsExt,
    path::Path,
};
extern crate walkdir;
use walkdir::WalkDir;

#[derive(Clone)]
pub struct Folder {
    /// File count of the files found
    file_count: i32,
    /// Current working directory
    current_path: String,
}

impl Folder {
    fn assign_path(to: &str) -> &Path {
        Path::new(to)
    }

    /// Returns the current working Directory
    pub fn get_current_path(&self) -> String {
        self.current_path.to_string()
    }

    /// changes the directory
    /// - Parameter to:  the path to change to
    /// - Returns: Result type of either () or ``FileError``
    pub fn change_directory(&mut self, to: String) -> Result<(), FileError> {
        let path = Self::assign_path(to.as_str());
        self.check_path(path)?;
        self.current_path = path.display().to_string();
        Ok(())
    }

    fn check_path(&self, path: &Path) -> Result<(), FileError> {
        if !path.is_dir() && path.is_file() {
            return Err(FileError::NotAFolder(path.display().to_string()));
        }
        if let Ok(exists) = path.try_exists() {
            if !exists {
                return Err(FileError::FileNotFound(path.display().to_string()));
            }
        }
        if let Err(_) = path.read_dir() {
            return Err(FileError::PermissionError(path.display().to_string()));
        }
        Ok(())
    }

    /// Prints out the files with their respective sizes
    ///
    /// - Parameters:
    ///   - from: the size of which the printed message must be higher than
    ///   - of: array containing the size, the file name and the numerical file size
    ///   - with: a closure for filtering the array
    pub fn list_folder_items<T>(&mut self, from: u64, of: Vec<(FileSize, String, u64)>, with: T)
    where
        T: Fn(FileSize, String, u64) -> bool,
    {
        let results = of
            .into_iter()
            .filter(|item| with(item.0, item.1.to_string(), item.2))
            .filter(|item| item.2 >= from);
        for result in results {
            self.increment();
            println!("{}", result.1);
        }
    }

    /// Crawls the current path non recursively but if anything goes wrong it returns an error
    ///  
    /// - Returns: Result type of either a vector of paths as strings or ``Folder.FileError``
    pub fn crawl_folder(&self) -> Result<Vec<String>, FileError> {
        let path = Self::assign_path(self.current_path.as_str());
        self.check_path(path)?;
        let mut result_path = vec!["".to_string()];
        if let Ok(subpath) = path.read_dir() {
            for sp in subpath {
                if let Ok(sp) = sp {
                    if let Some(pathname) = sp.path().to_str() {
                        result_path.push(pathname.to_string())
                    }
                }
            }
        }
        Ok(result_path)
    }

    /// Crawls the argument passed recursively but if anything goes wrong it returns an error
    ///
    /// - Parameter path: The path to be crawled
    /// - Returns: Result type of either a vector of paths as strings or ``Folder.FileError``
    pub fn crawl_folder_rec(self, user_path: String) -> Result<Vec<String>, FileError> {
        let path = Path::new(user_path.as_str());
        self.check_path(path)?;
        let subpaths = WalkDir::new(path)
            .min_depth(0)
            .follow_links(false)
            .same_file_system(false)
            .into_iter();
        let result = subpaths
            .filter_map(|subpath| {
                if let Ok(path) = subpath {
                    return Some(path.into_path().display().to_string());
                }
                None
            })
            .collect::<Vec<_>>();
        Ok(result)
    }

    fn increment(&mut self) {
        self.file_count += 1;
    }

    /// Constructor use to create an instance of this type
    pub fn new() -> Self {
        Folder {
            file_count: 0,
            current_path: std::env::current_dir().unwrap().display().to_string(),
        }
    }

    /// Crawls the root path non-recursively but anything goes wrong it returns an error
    ///
    /// - Returns: Result type of either a vector of paths as strings or ``Folder.FileError``
    pub fn crawl_root(&self) -> Result<Vec<String>, FileError> {
        let mut this = self.clone();
        this.change_directory("/".to_string())?;
        return this.crawl_folder();
    }

    pub fn find_size(&self, paths: Vec<String>) -> Vec<(FileSize, String, u64)> {
        let mut results = vec![];
        for path in paths {
            let path = Path::new(path.as_str());
            if let Ok(atrributes) = fs::metadata(path) {
                let (size, perm): (u64, Permissions) = (atrributes.len(), atrributes.permissions());
                if let Some(filesize) = FileSize::from(size) {
                    if let Some(actual_size) = filesize.sizer(size) {
                        let fi = (
                            filesize,
                            format!(
                                "{}  \t {}",
                                format!(
                                    "{}{}\t{}",
                                    actual_size,
                                    filesize,
                                    Self::change_permissions(perm.mode())
                                ),
                                path.display()
                            ),
                            actual_size,
                        );
                        results.push(fi);
                    }
                }
            }
        }
        return results;
    }

    fn change_permissions(perms: u32) -> String {
        let perm_string = format!("{:o}", perms).to_string();
        if perm_string.len() < 3 {
            return "----------".to_owned();
        }
        let permss = perm_string[perm_string.len() - 3..].to_string();
        let perms = permss.parse::<u32>().unwrap_or_default();
        let mut perm_to_string = "".to_string();
        let perm_value = [(4, "r"), (2, "w"), (1, "x")].into_iter();
        let msg = perms.to_string();
        for octal in msg.chars().into_iter() {
            let mut int_octal = octal.to_digit(8).unwrap();
            perm_value
                .as_slice()
                .into_iter()
                .for_each(|(int_value, str_value)| {
                    if int_octal >= *int_value {
                        perm_to_string += *str_value;
                        int_octal -= int_value;
                    } else {
                        perm_to_string += "-";
                    }
                });
        }
        return perm_to_string;
    }
}

impl Drop for Folder {
    fn drop(&mut self) {
        if self.file_count > 0 {
            println!("Scanned {} files in total", self.file_count);
        }
    }
}