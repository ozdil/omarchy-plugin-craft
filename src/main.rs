use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::env;
use std::fs;
use std::path::Path;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PluginItem {
    pub key: String,
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub path: String,
    pub exec_cmd: String,
    pub status_cmd: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ScanResult {
    pub status: String,
    pub total_plugins: usize,
    pub plugins: Vec<PluginItem>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct StatusOutput {
    pub text: String,
    pub tooltip: String,
    pub class: String,
}

#[derive(Deserialize, Debug)]
struct ManifestPartial {
    id: Option<String>,
    name: Option<String>,
    version: Option<String>,
    description: Option<String>,
}

fn sanitize(s: &str, max_len: usize) -> String {
    s.chars()
        .filter(|c| c.is_alphanumeric() || " ._-()[]".contains(*c))
        .take(max_len)
        .collect()
}

fn scan() -> ScanResult {
    let mut plugins = Vec::new();
    let mut seen_ids = HashSet::new();

    if let Ok(home) = env::var("HOME") {
        let pdir = Path::new(&home).join(".config/omarchy/plugins");
        if let Ok(entries) = fs::read_dir(&pdir) {
            let mut paths: Vec<_> = entries.flatten().map(|e| e.path()).collect();
            paths.sort();

            for p in paths {
                if p.is_dir() {
                    let key = p.file_name().unwrap_or_default().to_string_lossy().to_string();
                    if key.starts_with('.') || key == "plugin-craft" || key == "ozdil.plugin-craft" {
                        continue;
                    }
                    let mpath = p.join("manifest.json");
                    let clean_key = key.trim_start_matches("ozdil.").to_string();
                    let mut id = format!("ozdil.{}", clean_key);
                    let mut name = clean_key.replace('-', " ").to_uppercase();
                    let mut version = "1.1.0".to_string();
                    let mut desc = "Omarchy Native Plugin".to_string();

                    if mpath.is_file() {
                        if let Ok(content) = fs::read_to_string(&mpath) {
                            if let Ok(m) = serde_json::from_str::<ManifestPartial>(&content) {
                                if let Some(mid) = m.id {
                                    id = sanitize(&mid, 35);
                                }
                                if let Some(mname) = m.name {
                                    name = sanitize(&mname, 40);
                                }
                                if let Some(mver) = m.version {
                                    version = sanitize(&mver, 10);
                                }
                                if let Some(mdesc) = m.description {
                                    desc = sanitize(&mdesc, 80);
                                }
                            }
                        }
                    }

                    if seen_ids.contains(&id) {
                        continue;
                    }
                    seen_ids.insert(id.clone());

                    let mut exec_cmd = String::new();
                    for cand in &[format!("{}-dashboard", clean_key), "dashboard".to_string(), format!("{}-engine", clean_key)] {
                        let cp = p.join(cand);
                        if cp.is_file() {
                            exec_cmd = cp.to_string_lossy().to_string();
                            break;
                        }
                    }

                    let mut status_cmd = String::new();
                    for cand in &[format!("{}-status", clean_key), "status".to_string()] {
                        let cp = p.join(cand);
                        if cp.is_file() {
                            status_cmd = cp.to_string_lossy().to_string();
                            break;
                        }
                    }

                    plugins.push(PluginItem {
                        key: clean_key,
                        id,
                        name,
                        version,
                        description: desc,
                        path: p.to_string_lossy().to_string(),
                        exec_cmd,
                        status_cmd,
                    });
                }
            }
        }
    }

    plugins.sort_by(|a, b| a.name.cmp(&b.name));
    let total = plugins.len();

    ScanResult {
        status: "OK".to_string(),
        total_plugins: total,
        plugins,
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let res = scan();

    if args.iter().any(|a| a == "--status") {
        let text = format!("PLUGINS: {}", res.total_plugins);
        let tooltip = format!(
            "PluginCraft Hub\nTotal Plugins: {}\nEngine: Native Rust\nArchitecture: Zero CLI / Native UI",
            res.total_plugins
        );
        let out = StatusOutput {
            text,
            tooltip,
            class: "normal".to_string(),
        };
        println!("{}", serde_json::to_string(&out).unwrap());
        return;
    }

    if args.iter().any(|a| a == "--json" || a == "--scan") {
        println!("{}", serde_json::to_string(&res).unwrap());
        return;
    }

    println!("PLUGINCRAFT - NATIVE ARCH PLUGIN MANAGER");
    println!("Total Active Plugins: {}", res.total_plugins);
    println!("{:<20} {:<10} {:<30}", "KEY", "VERSION", "NAME");
    println!("{}", "-".repeat(65));
    for p in &res.plugins {
        println!("{:<20} {:<10} {:<30}", p.key, p.version, p.name);
    }
}
