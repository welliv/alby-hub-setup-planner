# Pitfall: toAppId Must Be Uint, Not String

**Error:** `400 Bad Request: Unmarshal type error: expected=uint, got=string, field=toAppId`

**Cause:** JavaScript `JSON.stringify()` serialises quoted strings differently from numbers:
- `JSON.stringify({ toAppId: 239 })` → `'{"toAppId":239}'` ✓
- `JSON.stringify({ toAppId: "239" })` → `'{"toAppId":"239"}'` ✗

The Hub's Go backend strictly expects a JSON number (uint). Any string value causes a 400.

**Common triggers:**
1. `String(appId)` called before storage in JSON file
2. Reading from JSON without `Number()` conversion
3. TypeScript type assertion as `string` instead of `number`
4. Function parameter typed as `number | string` that receives a string

**Debugging steps:**
1. Find the call site that sends the transfer request
2. Trace the `toAppId` value back to its source
3. Check if `String()` was called anywhere in the chain
4. Verify the compiled JS: `grep -A5 'function transferToApp' dist/app.js`

**Fix:** Ensure the value is a `number` at the point of `JSON.stringify()`. Store as number in JSON, read back with `Number()`. Never call `String()` on the ID before passing it to the request body.

**Verified fix pattern (2026-05-24, nwc-faucet):**
```typescript
// mapping.ts
map[username] = appId; // store as number, not String(appId)
const n = Number(map[username]); // read back with Number()
return Number.isNaN(n) ? undefined : n;

// app.ts transferToApp signature: (appId: number, amountSat: number)
// NOT: (appId: number | string, ...)
```
