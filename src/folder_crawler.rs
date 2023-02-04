extern crate structopt;
use crate::file_size::FileSize;
use std::path::PathBuf;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(
    name = "FolderCrawler",
    about = "This programs crawler the supplied path and print all files and their sizes"
)]
pub struct FolderCrawler {
    #[structopt(
        parse(from_os_str),
        help = "Path to crawl\n(If no folder is provided, it defaults to the current folder)"
    )]
    pub path: Option<PathBuf>,

    #[structopt(
        long,
        name = "ds",
        default_value = "unbounded",
        help = "Size to display. Available options: b, kb, mb, gb, tb, pb"
    )]
    pub data_size: FileSize,

    #[structopt(name = "subpaths", long, help = "Crawl subdirectories too")]
    pub sub_dir: bool,

    #[structopt(short, long, default_value, help = "Range of file sizes to include")]
    pub size: u64,

    #[structopt(long, help = "File or folder to exclude")]
    pub exclude: Option<PathBuf>
}

impl FolderCrawler {
    pub fn config() -> Self {
        Self::from_args()
    }
}
