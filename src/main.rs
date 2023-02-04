extern crate async_std;
extern crate futures;
extern crate rayon;
mod errors;
mod file_size;
mod folder;
mod folder_crawler;
use async_std::stream::StreamExt;
use errors::FileError;
use file_size::FileSize;
use folder::Folder;
use folder_crawler::*;
use rayon::prelude::*;

#[async_std::main]
async fn main() -> std::io::Result<()> {
    let path: String;
    let mut folder = folder::Folder::new();
    let cli = FolderCrawler::config();
    if let Some(pathbuf) = cli.path {
        path = pathbuf.display().to_string();
        if let Err(err) = folder.change_directory(path.to_string()) {
            exit(err);
        }
        println!("About to change to {}", path);
    } else {
        path = folder.get_current_path();
    }
    let exclude: String;
    if let Some(exc) = cli.exclude {
        let excluded = exc.display().to_string();
        if let Err(err) = Folder::new().change_directory(excluded.clone()) {
            exit(err);
        }
        exclude = excluded
    } else {
        exclude = String::from("");
    }

    let mut paths = vec![];
    paths.is_empty();
    if cli.sub_dir {
        if exclude.is_empty() {
            println!("About to search {} with its subdirectories", path);
        } else {
            println!("About to search {} with its subdirectories excluding {} and all its subdirectories", path, exclude);
        }
    } else {
        if exclude.is_empty() {
            println!("About to search {}", path);
        } else {
            println!(
                "About to search {} excluding {} and all its subdirectories",
                path, exclude
            );
        }
    }

    println!("Size   \tPermissions   \tFilePath");
    if path == String::from("/") && cli.sub_dir {
        if let Err(err) = for_root(&mut folder, cli.data_size, cli.size, exclude).await {
            exit(err);
        }
        return Ok(());
    } else if path == String::from("/") && !cli.sub_dir {
        if let Err(err) = folder.clone().crawl_folder() {
            exit(err);
        }
        paths = folder.clone().crawl_folder().unwrap();
        if !exclude.is_empty() {
            paths = filter_out(paths, exclude);
        }
        let results = folder.find_size(paths);
        list_items(cli.size, cli.data_size, &mut folder, results);
        return Ok(());
    }
    if cli.sub_dir {
        if let Err(err) = folder.clone().crawl_folder_rec(folder.get_current_path()) {
            exit(err);
        }
        paths = folder
            .clone()
            .crawl_folder_rec(folder.get_current_path())
            .unwrap();
        if !exclude.is_empty() {
            paths = filter_out(paths, exclude);
        }
        let results = folder.find_size(paths);
        list_items(cli.size, cli.data_size, &mut folder, results);
    } else {
        if let Err(err) = folder.clone().crawl_folder() {
            exit(err);
        }
        paths = folder.clone().crawl_folder().unwrap();
        if !exclude.is_empty() {
            paths = filter_out(paths, exclude);
        }
        let results = folder.find_size(paths);
        list_items(cli.size, cli.data_size, &mut folder, results);
    }
    Ok(())
}

fn exit<E>(err: E)
where
    E: std::error::Error,
{
    eprintln!("Error: {err}");
    std::process::exit(1)
}

async fn for_root(
    folder: &mut Folder,
    file_size: FileSize,
    size: u64,
    exclude: String,
) -> Result<(), FileError> {
    let root_path = folder.crawl_root()?;
    let count = std::thread::available_parallelism()
        .unwrap_or(std::num::NonZeroUsize::new(8).unwrap())
        .get();
    let root_paths = root_path.chunks(count).collect::<Vec<_>>();
    let (tx, rx) = std::sync::mpsc::channel();
    let handles = (0..root_paths.capacity())
        .into_par_iter()
        .map_with(tx, |tx, index| {
            let tx = tx.clone();
            let exclude = exclude.clone();
            return async_std::task::spawn(async move {
                let root_path = Folder::new().crawl_root().unwrap();
                let root_paths = root_path.chunks(8).collect::<Vec<_>>();
                let paths = root_paths[index];
                let tx = tx.clone();
                futures::executor::block_on(async move {
                    async_std::stream::from_iter(paths)
                        .for_each(move |path| {
                            let path = path.to_string();
                            if let Some(result) = find(path, exclude.clone()) {
                                tx.send(result).unwrap()
                            }
                        })
                        .await;
                });
            });
        })
        .collect::<Vec<_>>();

    futures::future::join_all(handles).await;

    for results in rx.into_iter() {
        list_items(size, file_size, folder, results)
    }
    Ok(())
}

fn find(path: String, exclude: String) -> Option<Vec<(FileSize, String, u64)>> {
    let mut fold = Folder::new();
    if let Err(_) = fold.change_directory(path.to_string()) {
        return None;
    }
    let current_path = fold.get_current_path();
    if let Ok(res) = fold.clone().crawl_folder_rec(current_path) {
        let mut res = res;
        if !exclude.is_empty() {
            res = filter_out(res, exclude)
        }
        let result = fold.find_size(res);
        return Some(result);
    }
    None
}

fn list_items(
    size: u64,
    data_size: FileSize,
    folder: &mut Folder,
    result: Vec<(FileSize, String, u64)>,
) {
    if data_size == FileSize::Unbounded {
        folder.list_folder_items(size, result, |_, _, _| true);
    } else {
        folder.list_folder_items(size, result, move |sizetype, _, _| data_size == sizetype);
    }
}

fn filter_out(list: Vec<String>, exclude: String) -> Vec<String> {
    list.into_iter()
        .filter_map(|item| {
            if !(item.starts_with(&exclude) || item == exclude) {
                return Some(item);
            }
            None
        })
        .collect::<Vec<_>>()
}
