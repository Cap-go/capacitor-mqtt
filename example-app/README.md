# Example App for `@capgo/capacitor-mqtt`

This Vite project links directly to the local plugin source so you can exercise broker connections, subscriptions, publishes, and event callbacks while developing.

## Getting started

```bash
bun install
bun run start
```

To test on native shells:

```bash
bunx cap add ios
bunx cap add android
bunx cap sync
```

The web implementation is intentionally minimal and may throw for native-only behavior. Use a simulator or device to validate full broker connectivity.
