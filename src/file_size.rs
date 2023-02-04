use std::{fmt::Display, str::FromStr};

const B_LIMIT: u64 = 1024 - 1;
const B: u64 = 1024;
const KB_LIMIT: u64 = 1048575;
const KB: u64 = 1048576;
const MB_LIMIT: u64 = 1073741823;
const MB: u64 = 1073741824;
const GB_LIMIT: u64 = 1099511627775;
const GB: u64 = 1099511627776;
const TB_LIMIT: u64 = 1125899906842623;
const TB: u64 = 1125899906842624;
const PB_LIMIT: u64 = 1152921504606846975;

/// A computer file data size representation
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum FileSize {
    B,
    KB,
    MB,
    GB,
    TB,
    PB,
    Unbounded,
}

/// Conversion Error
#[derive(Debug)]
pub struct ConvError(String);

impl Display for ConvError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Failed to convert {} to a valid file size", self.0)
    }
}

impl FromStr for FileSize {
    type Err = ConvError;

    /**
      Initializes this type to the appropriate case from the argument passed otherwise fails and returns error
    - Parameter value: string value
    - Returns: Result type of either ``FileSize`` or an error
    */
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "b" | "B" => Ok(Self::B),
            "kb" | "KB" => Ok(Self::KB),
            "mb" | "MB" => Ok(Self::MB),
            "gb" | "GB" => Ok(Self::GB),
            "tb" | "TB" => Ok(Self::TB),
            "pb" | "PB" => Ok(Self::PB),
            "unbounded" | "Unbounded" | "UNBOUNDED" => Ok(Self::Unbounded),
            _ => Err(ConvError(s.to_string())),
        }
    }
}

impl Display for FileSize {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match *self {
            FileSize::B => write!(f, "b"),
            FileSize::KB => write!(f, "kb"),
            FileSize::MB => write!(f, "mb"),
            FileSize::GB => write!(f, "gb"),
            FileSize::TB => write!(f, "tb"),
            FileSize::PB => write!(f, "pb"),
            FileSize::Unbounded => writeln!(f, "unbounded"),
        }
    }
}

impl FileSize {
    /// Uses the argument passed to create an appropriate ``FileSize`` instance otherwise fails and return nil
    /// - Parameter value: the file size as an u64 value
    /// - Returns: ``FileSize`` or None if anything goes wrong
    pub fn from(value: u64) -> Option<Self> {
        return match value {
            0 ..= B_LIMIT => Some(Self::B),
            B ..= KB_LIMIT => Some(Self::KB),
            KB ..= MB_LIMIT => Some(Self::MB),
            MB ..= GB_LIMIT => Some(Self::GB),
            GB ..= TB_LIMIT => Some(Self::TB),
            TB ..= PB_LIMIT => Some(Self::PB),
            _ => None,
        };
    }

    /// First converts the argument passed to a ``FileSize`` instance, then returns the file size as an u64 value otherwise fails and returns nil
    /// - Parameter value: Argument value to convert to an ``FileSize`` instance
    /// - Returns: File size value of the appropriate ``FileSize`` case as a u64 value or nil if anything goes wrong
    pub fn sizer(&self, value: u64) -> Option<u64> {
        if let Some(fs) = FileSize::from(value) {
            return match fs {
                FileSize::B => Some(value),
                FileSize::KB => Some(value / B),
                FileSize::MB => Some(value / KB),
                FileSize::GB => Some(value / MB),
                FileSize::TB => Some(value / GB),
                FileSize::PB => Some(value / TB),
                FileSize::Unbounded => None,
            };
        }
        None
    }
}
