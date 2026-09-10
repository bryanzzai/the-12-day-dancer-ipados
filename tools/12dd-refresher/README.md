# 12DD Refresher (Windows prototype)

A deliberately small Windows-side refresher for **The 12 Day Dancer**.

## Why Windows-side?

A refresher app installed on the iPhone with a free Personal Team would itself expire after roughly seven days. This tool instead runs on Windows and refreshes 12DD from outside the phone.

## Important design choice

The first interactive `setup`/`reauth` logs into Apple and requests the Xcode app-token used by the developer services. The tool stores **only that app-token + ADSID** in Windows Credential Manager. It does **not** store the Apple ID password.

Normal `refresh` reconstructs an `isideload::DeveloperSession` directly from the cached app-token and ADSID. Therefore a routine refresh does not deliberately perform the full Apple ID/password GrandSlam login again. If Apple expires/rejects that app-token, run `reauth` interactively.

The prototype pins nab138/isideload commit `f2fd29abbb45a49fb79fdec22aa405cca05a5777`, which contains the Sep 10, 2026 GSA/X-Mme-Client-Info fix.

## Commands

```text
12dd-refresher setup <apple-id> <path-to-12dd.ipa>
12dd-refresher reauth
12dd-refresher refresh [--force]
12dd-refresher status
```

`setup` requires a connected/trusted iPhone only when you immediately run refresh. `refresh` currently uses the first device visible through usbmuxd and should initially be tested over USB.

## Backoff policy

- after a successful refresh: do not try again for 48 hours
- Apple HTTP 429: back off for 6 hours
- other failures: back off for 1 hour

The intent is to give us a large safety margin inside Apple's ~7-day Personal Team window without hammering Apple's services.

## Prototype limitations

This is v0.1, not a SideStore replacement. It does not yet inspect the provisioning profile installed on the phone, select a specific UDID, run as a tray app, or register its own Windows Scheduled Task. Those are the next steps after the basic token-cache + re-sign + reinstall path is proven on Bryan's iPhone 12 Pro Max.
