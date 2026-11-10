# Admin dashboard

Use the app's normal Login screen and enter the owner's email and password. The server checks the password, requires the admin account's email to be verified, and returns the saved account role. Admins open the regular map-based app shell with Explore, Feed and an Admin tab; the Admin tab contains the dashboard. Regular accounts keep the normal tabs.

Admin permissions are checked on the backend against the signed token and current account role. The password and owner identity are not hardcoded into the app. The designated owner's account is the only account with admin privileges.

For Android testing, install build/app/outputs/flutter-apk/tilomnov-production.apk from the configured desktop APK directory. The same normal login flow applies to iPhone builds, without a deep-link entitlement requirement.

The dashboard shows account counts/growth, listings, leads, open reports, subscription tiers, and recent payment volume. Simulated payment volume is labeled. Crash, retention, and API latency measurements are not yet part of this data source.

Tap any metric, payment total or plan chip to open its matching detail list. Tap a record to expand its selected information, including usernames and account contact details. Every list scrolls, supports pull to refresh, and loads another 50 records with Load more; a failed next page preserves the records already shown. Active users means accounts that have not been deactivated.

The expandable Backend services panel independently shows gateway, authentication, users, listings, chat, payments and notification HTTP status, response times, and the last check time. Check again refreshes the probes; dashboard refresh reloads both metrics and service status. Missing service addresses are shown as unconfigured. HTTP checks establish whether a service responds, not database, Redis or provider readiness. Backend configuration and endpoint details are in `genie-backend/docs/ADMIN_DASHBOARD.md`.
