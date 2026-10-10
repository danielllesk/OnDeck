import { createSign, randomUUID } from "node:crypto"
import { readFileSync } from "node:fs"
import http2 from "node:http2"

type ApnsConfig = {
  keyId: string
  teamId: string
  bundleId: string
  keyPath: string
  production: boolean
}

let cachedToken: { value: string; issuedAt: number } | null = null

export function apnsConfigFromEnv(env = process.env): ApnsConfig | null {
  const keyId = env.APNS_KEY_ID
  const teamId = env.APNS_TEAM_ID
  const bundleId = env.APNS_BUNDLE_ID
  const keyPath = env.APNS_KEY_PATH
  if (!keyId || !teamId || !bundleId || !keyPath) return null
  return {
    keyId,
    teamId,
    bundleId,
    keyPath,
    production: env.APNS_PRODUCTION === "true",
  }
}

export async function sendApns(token: string, title: string, body: string): Promise<boolean> {
  const config = apnsConfigFromEnv()
  if (!config) return false

  const jwt = appleJwt(config)
  const host = config.production ? "api.push.apple.com" : "api.sandbox.push.apple.com"
  const client = http2.connect(`https://${host}`)
  const payload = JSON.stringify({
    aps: { alert: { title, body }, sound: "default" },
  })

  try {
    const status = await new Promise<number>((resolve, reject) => {
      const request = client.request({
        ":method": "POST",
        ":path": `/3/device/${token}`,
        authorization: `bearer ${jwt}`,
        "apns-topic": config.bundleId,
        "apns-push-type": "alert",
        "apns-id": randomUUID(),
      })
      request.setEncoding("utf8")
      request.on("response", (headers) => {
        resolve(Number(headers[":status"] ?? 0))
      })
      request.on("error", reject)
      request.end(payload)
    })
    return status === 200
  } finally {
    client.close()
  }
}

export function appleJwt(config: ApnsConfig, nowSeconds = Math.floor(Date.now() / 1000)): string {
  if (cachedToken && nowSeconds - cachedToken.issuedAt < 50 * 60) return cachedToken.value
  const header = base64url(JSON.stringify({ alg: "ES256", kid: config.keyId }))
  const claims = base64url(JSON.stringify({ iss: config.teamId, iat: nowSeconds }))
  const unsigned = `${header}.${claims}`
  const signer = createSign("SHA256")
  signer.update(unsigned)
  signer.end()
  const der = signer.sign(readFileSync(config.keyPath))
  const token = `${unsigned}.${base64url(derToRaw(der))}`
  cachedToken = { value: token, issuedAt: nowSeconds }
  return token
}

function derToRaw(der: Buffer): Buffer {
  let offset = 2
  if (der[1] & 0x80) offset = 2 + (der[1] & 0x7f)
  if (der[offset] !== 0x02) throw new Error("invalid APNs signature")
  const rLength = der[offset + 1]
  let r = der.subarray(offset + 2, offset + 2 + rLength)
  const sStart = offset + 2 + rLength
  if (der[sStart] !== 0x02) throw new Error("invalid APNs signature")
  const sLength = der[sStart + 1]
  let s = der.subarray(sStart + 2, sStart + 2 + sLength)
  if (r[0] === 0x00) r = r.subarray(1)
  if (s[0] === 0x00) s = s.subarray(1)
  const raw = Buffer.alloc(64)
  r.copy(raw, 32 - r.length)
  s.copy(raw, 64 - s.length)
  return raw
}

function base64url(value: string | Buffer): string {
  return Buffer.from(value)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
}
