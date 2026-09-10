use anyhow::{anyhow, Context, Result};
use chrono::Utc;
use idevice::usbmuxd::{UsbmuxdAddr, UsbmuxdConnection};
use isideload::{
    anisette::remote_v3::RemoteV3AnisetteProvider,
    auth::apple_account::{AppToken, AppleAccount, TwoFactorCallbackParams, TwoFactorCallbackResponse},
    dev::developer_session::DeveloperSession,
    sideload::{builder::MaxCertsBehavior, SideloaderBuilder, TeamSelection},
    util::keyring_storage::KeyringStorage,
};
use keyring::Entry;
use serde::{Deserialize, Serialize};
use std::{env, fs, path::PathBuf};

const SERVICE_SESSION: &str = "12dd-refresher-session";
const SERVICE_STORAGE: &str = "12dd-refresher";
const SUCCESS_INTERVAL_SECS: i64 = 48 * 60 * 60;
const RETRY_429_SECS: i64 = 6 * 60 * 60;
const RETRY_OTHER_SECS: i64 = 60 * 60;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    email: String,
    ipa_path: String,
    last_success_unix: Option<i64>,
    next_attempt_unix: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CachedSession {
    token: String,
    duration: u64,
    expiry: u64,
    adsid: String,
}

fn rc<E: std::fmt::Debug>(e: E) -> anyhow::Error {
    anyhow!("{e:?}")
}

fn config_path() -> Result<PathBuf> {
    let base = env::var_os("APPDATA")
        .map(PathBuf::from)
        .unwrap_or(env::current_dir()?);
    Ok(base.join("12DDRefresher").join("config.json"))
}

fn load_config() -> Result<Config> {
    let path = config_path()?;
    let bytes = fs::read(&path).with_context(|| format!("No config found at {}. Run setup first.", path.display()))?;
    Ok(serde_json::from_slice(&bytes)?)
}

fn save_config(config: &Config) -> Result<()> {
    let path = config_path()?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(path, serde_json::to_vec_pretty(config)?)?;
    Ok(())
}

fn session_entry(email: &str) -> Result<Entry> {
    Entry::new(SERVICE_SESSION, email).map_err(rc)
}

fn save_session(email: &str, session: &CachedSession) -> Result<()> {
    session_entry(email)?
        .set_password(&serde_json::to_string(session)?)
        .map_err(rc)
}

fn load_session(email: &str) -> Result<CachedSession> {
    let raw = session_entry(email)?
        .get_password()
        .map_err(|e| anyhow!("No cached Apple developer token found. Run reauth. ({e})"))?;
    Ok(serde_json::from_str(&raw)?)
}

fn anisette_provider() -> Result<RemoteV3AnisetteProvider> {
    Ok(RemoteV3AnisetteProvider::default()
        .map_err(rc)?
        .set_serial_number("0".to_string())
        .set_storage(Box::new(KeyringStorage::new(SERVICE_STORAGE.to_string()))))
}

async fn interactive_login_and_cache(email: &str) -> Result<CachedSession> {
    println!("Apple ID: {email}");
    let password = rpassword::prompt_password("Apple ID password: ")?;

    let two_factor = |params: TwoFactorCallbackParams| async move {
        if params.sms {
            println!("Enter the Apple 2FA code sent by SMS:");
        } else {
            println!("Enter the Apple 2FA code shown on your trusted device:");
        }
        let mut code = String::new();
        std::io::stdin().read_line(&mut code).unwrap();
        Ok(TwoFactorCallbackResponse::SubmitCode(code.trim().to_string()))
    };

    let mut account = AppleAccount::builder(&email.to_lowercase())
        .anisette_provider(anisette_provider()?)
        .login(&password, two_factor)
        .await
        .map_err(rc)?;

    let adsid = account
        .spd
        .as_ref()
        .and_then(|d| d.get("adsid"))
        .and_then(|v| v.as_string())
        .context("Apple login succeeded but no ADSID was returned")?
        .to_string();

    let token = account.get_app_token("xcode.auth").await.map_err(rc)?;
    let cached = CachedSession {
        token: token.token,
        duration: token.duration,
        expiry: token.expiry,
        adsid,
    };
    save_session(email, &cached)?;
    println!("Cached Xcode app-token securely in Windows Credential Manager.");
    Ok(cached)
}

async fn refresh(config: &mut Config, force: bool) -> Result<()> {
    let now = Utc::now().timestamp();
    if !force {
        if let Some(next) = config.next_attempt_unix {
            if now < next {
                println!("Not due yet; next attempt after Unix time {next}.");
                return Ok(());
            }
        }
        if let Some(last) = config.last_success_unix {
            if now - last < SUCCESS_INTERVAL_SECS {
                println!("12DD was refreshed less than 48 hours ago; skipping.");
                return Ok(());
            }
        }
    }

    let cached = load_session(&config.email)?;
    let account = AppleAccount::builder(&config.email.to_lowercase())
        .anisette_provider(anisette_provider()?)
        .build()
        .await
        .map_err(rc)?;

    let dev_session = DeveloperSession::new(
        AppToken {
            token: cached.token,
            duration: cached.duration,
            expiry: cached.expiry,
        },
        cached.adsid,
        account.grandslam_client.clone(),
        account.anisette_generator.clone(),
    );

    let mut usbmuxd = UsbmuxdConnection::default().await.map_err(rc)?;
    let devices = usbmuxd.get_devices().await.map_err(rc)?;
    let device = devices.first().context("No iPhone/iPad found. Connect the iPhone by USB and trust this PC.")?;
    let addr = UsbmuxdAddr::from_env_var().map_err(rc)?;
    let provider = device.to_provider(addr, "12dd-refresher");

    let mut sideloader = SideloaderBuilder::new(dev_session, config.email.to_lowercase())
        .team_selection(TeamSelection::First)
        .max_certs_behavior(MaxCertsBehavior::Error)
        .storage(Box::new(KeyringStorage::new(SERVICE_STORAGE.to_string())))
        .machine_name("12DD Refresher".to_string())
        .build();

    let result = sideloader
        .install_app(
            &provider,
            PathBuf::from(&config.ipa_path),
            true,
            None::<fn(f32) -> std::future::Ready<()>>,
        )
        .await;

    match result {
        Ok(_) => {
            config.last_success_unix = Some(now);
            config.next_attempt_unix = Some(now + SUCCESS_INTERVAL_SECS);
            save_config(config)?;
            println!("The 12 Day Dancer refreshed successfully.");
            Ok(())
        }
        Err(e) => {
            let text = format!("{e:?}");
            if text.contains("429 Too Many Requests") || text.contains("429") {
                config.next_attempt_unix = Some(now + RETRY_429_SECS);
                save_config(config)?;
                Err(anyhow!("Apple returned 429. Backing off for 6 hours.\n{text}"))
            } else {
                config.next_attempt_unix = Some(now + RETRY_OTHER_SECS);
                save_config(config)?;
                Err(anyhow!("Refresh failed. Next automatic attempt allowed in 1 hour.\n{text}"))
            }
        }
    }
}

fn usage() {
    eprintln!("12DD Refresher\n\n  setup <apple-id> <path-to-12dd.ipa>\n  reauth\n  refresh [--force]\n  status\n");
}

#[tokio::main]
async fn main() -> Result<()> {
    let _ = rustls::crypto::ring::default_provider().install_default();
    isideload::init().map_err(rc)?;

    let args: Vec<String> = env::args().collect();
    match args.get(1).map(String::as_str) {
        Some("setup") => {
            let email = args.get(2).context("Missing Apple ID")?.to_lowercase();
            let ipa = args.get(3).context("Missing path to 12DD IPA")?.to_string();
            let path = PathBuf::from(&ipa);
            if !path.exists() {
                return Err(anyhow!("IPA does not exist: {}", path.display()));
            }
            interactive_login_and_cache(&email).await?;
            let config = Config {
                email,
                ipa_path: ipa,
                last_success_unix: None,
                next_attempt_unix: None,
            };
            save_config(&config)?;
            println!("Setup complete. Run: 12dd-refresher refresh --force");
        }
        Some("reauth") => {
            let config = load_config()?;
            interactive_login_and_cache(&config.email).await?;
            println!("Apple developer token renewed.");
        }
        Some("refresh") => {
            let mut config = load_config()?;
            let force = args.iter().any(|a| a == "--force");
            refresh(&mut config, force).await?;
        }
        Some("status") => {
            let config = load_config()?;
            println!("Apple ID: {}", config.email);
            println!("IPA: {}", config.ipa_path);
            println!("Last success: {:?}", config.last_success_unix);
            println!("Next attempt: {:?}", config.next_attempt_unix);
            let session = load_session(&config.email)?;
            println!("Cached developer token expiry (Apple value): {}", session.expiry);
        }
        _ => usage(),
    }

    Ok(())
}
