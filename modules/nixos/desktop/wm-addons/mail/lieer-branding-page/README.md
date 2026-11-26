# Lieer OAuth Branding Page

Static homepage (`index.html`) and privacy policy (`privacy.html`) required by Google Auth Platform to publish a personal Google OAuth 2.0 Desktop client for `lieer` (which avoids the 7-day refresh token expiration in *Testing* mode).

This is hosted on **Cloudflare Workers Static Assets** (free plan: unlimited static asset requests, built-in DDoS protection, automatic TLS, zero load on `gvps`).

## Deploy to Cloudflare Workers

1. If you are reusing this for a different domain or email, update `lieer.geanmar.com` and `gean.marroquin@gmail.com` in `index.html` and `privacy.html`.
2. In the [Cloudflare Dashboard](https://dash.cloudflare.com/):
   - Go to **Compute (Workers) → Workers & Pages → Create → Create an application**.
   - Choose **Upload your static files** (or **Pages → Direct Upload**), name the project (e.g. `lieer-branding-page`), and upload `index.html` and `privacy.html` from this directory (do not upload `README.md`).
   - Deploy the project.
3. Attach a custom domain:
   - Open the Worker/Pages project → **Settings → Domains & Routes → Add → Custom domain**.
   - Enter `lieer.geanmar.com` (Cloudflare automatically creates the proxied DNS record and TLS certificate).
4. Verify both URLs load:
   - `https://lieer.geanmar.com`
   - `https://lieer.geanmar.com/privacy.html` (or `/privacy`)

## Google Auth Platform Configuration

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project and enable **Gmail API**.
2. Under **Google Auth Platform → Data Access**, add the three scopes `lieer` requests:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.labels`
   - `https://www.googleapis.com/auth/gmail.modify`
3. Under **Google Auth Platform → Branding**:
   - **Application home page:** `https://lieer.geanmar.com`
   - **Application privacy policy link:** `https://lieer.geanmar.com/privacy.html`
   - **Authorized domains:** `geanmar.com`
4. Under **Google Auth Platform → Audience**, click **Publish app** (you do not need to submit for Google verification; click **Advanced → Continue** on the one-time unverified-app prompt during `gmi auth`).
5. Under **Google Auth Platform → Clients**, create a **Desktop app** OAuth client, download its JSON, and authorize `lieer`:
   ```sh
   cd ~/Mail/<AccountName>
   gmi auth -f -c /path/to/client_secret.json
   ```
