/*
 * Freljord Falls — Cloudflare TURN credential minter (Cloudflare Worker)
 * ----------------------------------------------------------------------
 * GitHub Pages can't keep a secret, so this tiny Worker holds your Cloudflare
 * Realtime TURN API token and hands the game short-lived ICE servers on request.
 * TURN relays the data through Cloudflare's network, which gets players connected
 * even on hotel WiFi, mobile data, and CGNAT/symmetric-NAT networks.
 *
 * ── SETUP (all in the Cloudflare dashboard, ~5 min, free) ──────────────────
 *  1. Sign up / log in at https://dash.cloudflare.com  (no credit card needed)
 *
 *  2. Create a TURN key:
 *       Left sidebar → "Realtime"  (older accounts may call it "Calls")
 *         → "TURN"  →  "Create TURN key"  →  name it "freljord"  →  Save.
 *       Copy the two values it shows:
 *         • TURN Key ID
 *         • TURN Key API Token   (shown only once — copy it now)
 *
 *  3. Create the Worker:
 *       Left sidebar → "Workers & Pages" → "Create" → "Create Worker"
 *         → name it "freljord-turn" → "Deploy" → "Edit code".
 *       Delete the sample code, paste THIS entire file, then "Deploy".
 *
 *  4. Add your secrets to the Worker:
 *       Worker → "Settings" → "Variables and Secrets" → add two variables:
 *         TURN_KEY_ID         = <your TURN Key ID>
 *         TURN_KEY_API_TOKEN  = <your TURN Key API Token>   (click "Encrypt")
 *       → "Deploy" again.
 *
 *  5. Copy the Worker's URL (looks like https://freljord-turn.<you>.workers.dev)
 *     and send it to me — I'll paste it into index.html's TURN_ENDPOINT and
 *     redeploy the game. (Or paste it there yourself and push.)
 *
 * Test it any time by opening the Worker URL in a browser — you should see JSON
 * with an "iceServers" array containing turn: URLs, a username, and a credential.
 */
export default {
  async fetch(request, env) {
    const cors = {
      'Access-Control-Allow-Origin': '*',            // optional: lock to 'https://shoonville.github.io'
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors });
    try {
      const res = await fetch(
        `https://rtc.live.cloudflare.com/v1/turn/keys/${env.TURN_KEY_ID}/credentials/generate-ice-servers`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.TURN_KEY_API_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ ttl: 86400 }), // credentials valid for 24h
        }
      );
      const body = await res.text();
      return new Response(body, {
        status: res.ok ? 200 : 502,
        headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: cors });
    }
  },
};
