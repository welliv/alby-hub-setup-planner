# LNURL Pay Endpoint for LightningAddress SDK Compatibility

## Problem

`POST /api/lightning-addresses` on Alby Hub requires a live Alby account OAuth session. On self-hosted or freshly-setup Hubs, this fails with:

```
oauth2: token expired and refresh token is not set
```

When that happens, the `LightningAddress` class from `@getalby/lightning-tools` cannot resolve LNURL pay data, and wallet creation in the faucet fails.

## Solution

Serve `/.well-known/lnurlp/<username>` and `/lnurlp/<username>/callback` directly from the faucet backend, bypassing the Hub's lightning address API entirely.

## Implementation

### 1. `GET /.well-known/lnurlp/<username>`

Look up `username → appId` from the mapping file. Return LNURL metadata:

```json
{
  "status": "OK",
  "tag": "payRequest",
  "callback": "https://faucet.example.com/lnurlp/<username>/callback",
  "minSendable": 1000,
  "maxSendable": 1000000000,
  "metadata": "[[\"text/plain\", \"Payment to <username>\"]]",
  "commentAllowed": 0
}
```

### 2. `GET /lnurlp/<username>/callback?amount=<millisats>`

Create an invoice via Hub's `POST /api/invoices`:

```typescript
// Key: amount is millisats, not sats
const amountSat = Math.floor(amountMillisats / 1000);
const invoice = await createInvoice({ amountSat, description: `Payment to ${username}` });
```

**Critical:** Hub returns `invoice` (not `paymentRequest`) in the response. Use `invoice` as the `pr` field.

Return:

```json
{
  "status": "OK",
  "pr": "<bolt11-invoice>",
  "routes": []
}
```

## Reference Implementation

See `src/app.ts` in the [nwc-faucet](https://github.com/welliv/nwc-faucet) repo (commit `51498bd`).

## Notes

- This workaround is only needed when `GET /api/info` shows `oauthRedirect: false` or `albyAccountConnected: false`
- The NWC connection (pairingUri) and `lud16` remain fully usable without the Hub's lightning address
- `createLightningAddress` should be wrapped in try/catch and treated as best-effort
