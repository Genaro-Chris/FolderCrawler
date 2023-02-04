use std::{error::Error, fmt::Display};

/// Errors associated with crawling directory
#[allow(dead_code)]
#[derive(Debug)]
pub enum FileError {
    /// Missing file
    FileNotFound(String),
    /// Permission file error
    PermissionError(String),
    /// Not a directory
    NotAFolder(String),
}

impl Error for FileError {}

impl Clone for FileError {
    fn clone(&self) -> Self {
        match self {
            Self::FileNotFound(pathname) => Self::FileNotFound(pathname.clone()),
            Self::PermissionError(pathname) => Self::PermissionError(pathname.clone()),
            Self::NotAFolder(pathname) => Self::NotAFolder(pathname.clone()),
        }
    }
}

impl Display for FileError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FileError::FileNotFound(pathname) => {
                writeln!(f, "Folder {} is invalid or missing", pathname)
            }
            FileError::PermissionError(pathname) => writeln!(
                f,
                "Invalid permissions to enumerate of this folder {}",
                pathname
            ),
            FileError::NotAFolder(pathname) => writeln!(f, "{} is not a directory", pathname),
        }
    }
}
