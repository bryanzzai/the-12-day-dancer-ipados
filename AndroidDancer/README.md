# The 12 Day Dancer — Android / Samsung Galaxy A16

Native Android edition of Bryan MacKayne's The 12 Day Dancer.

## Design contract

- Visual reference: `iphone-12-pro-max` branch.
- Same 12-album order, titles, subtitles, descriptions and Roman numerals.
- Same `ConcertResources` bundle filenames as the iPhone SideStore Lite edition.
- Audio: 229 web M4A tracks.
- Video: 9 Dies Akita MP4 films.
- The APK contains the generated catalog and the ballerina facade only; the permanent media/art library remains external.

## First run

1. Install the APK on Android.
2. Open The 12 Day Dancer.
3. Tap **CHOOSE CONCERTRESOURCES**.
4. Select the existing `ConcertResources` folder.
5. Android stores a persistent Storage Access Framework permission for that folder.

No Apple provisioning, SideStore, LocalDevVPN or seven-day refresh cycle is involved.

## Build

GitHub Actions workflow: `.github/workflows/build-android-galaxy-a16.yml`.

The workflow clones `bryanzzai/bryanmackayne`, regenerates the Android catalog from the same source of truth used by iPhone, validates 12 albums / 229 audio tracks / 9 films, then builds a debug APK.

The first APK uses Android's debug signing for hardware testing. Before treating the Android edition as the permanent production copy, create one long-lived private Android signing key and keep it outside the public repository; all future release APKs must use that same key so Android can update the installed app in place.
