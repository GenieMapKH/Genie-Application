# Admin Services

Services includes HTTP health, Infisical rotation timestamps and a confirmed **Force rotate
all** action, a paginated Sentry Logs/Errors feed with pause/resume, and confirmed per-service
Railway recovery. Each panel handles its own loading/failure state. The controls use the
existing admin MFA session; provider credentials stay on the backend.

Configure the backend integrations and GitHub handover settings before enabling these
controls in production. See the backend [Admin Services setup and API contracts](../../genie-backend/docs/ADMIN_SERVICES.md).

Force rotation asks for confirmation without a reason field; the app supplies the audit
description automatically. The admin map has a Messenger shortcut above the UTM button
that opens the existing chat inbox without adding a bottom navigation item.

Force rotation covers six database credentials, the shared internal secret and JWT key
encryption. Existing user sessions remain valid. External provider keys are managed
separately. Deployment handovers need a staging test before production use.

The Sentry feed polls every ten seconds for events in the last 24 hours. Scrolling or
loading older events pauses it. Failed refreshes preserve visible data. Enable backend
application log forwarding with `SENTRY_ENABLE_LOGS=true`; only ingested Sentry events appear.

Rollback targets the previous retained successful deployment of each affected service,
requires a reason, and is blocked when managed credentials differ. It does not undo database
migrations or mobile releases. Railway remains the recovery path if the admin API is down.
