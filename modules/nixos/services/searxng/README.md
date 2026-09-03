# SearXNG

## Google proxy

The module can route only the Google engine through a proxy. Other engines use
the host's normal network connection.

Configure a credential-free proxy endpoint on the SearXNG host:

```nix
_custom.services.searxng = {
  enable = true;
  googleProxy = "socks5h://127.0.0.1:1080";
};
```

`googleProxy` is written to the Nix store. Do not put a username, password, or
token in the URL. When authentication is required, run a local proxy that holds
the credentials and point SearXNG at its unauthenticated loopback listener.

Supported examples include:

```nix
googleProxy = "socks5h://127.0.0.1:1080";
# googleProxy = "http://127.0.0.1:8080";
```

Prefer `socks5h` over `socks5` in the SearXNG setting so DNS resolution also
happens through the proxy.

### Temporary SSH SOCKS proxy

For testing, create a SOCKS proxy on the same host that runs SearXNG:

```console
$ ssh -N \
    -D 127.0.0.1:1080 \
    -o ExitOnForwardFailure=yes \
    user@egress-host
```

Keep the SSH connection running while SearXNG uses Google. For regular use,
manage the tunnel as a persistent service with restart and keepalive behavior.
The proxy must be available before sending Google searches.

Verify its public address:

```console
$ curl --proxy socks5h://127.0.0.1:1080 https://api.ipify.org
```

## Handling a Google CAPTCHA

Google's CAPTCHA is returned to the SearXNG backend, so it cannot be displayed
or completed in the SearXNG interface. A manual attempt must use the same proxy
and therefore the same public egress IP as the Google engine.

Launch a separate Chrome profile through the local proxy:

```console
$ google-chrome-stable \
    --user-data-dir=/tmp/google-proxy-profile \
    --proxy-server="socks5://127.0.0.1:1080" \
    "https://www.google.com/search?q=test"
```

Chrome uses `socks5://` in its command-line proxy syntax; the corresponding
SearXNG URL remains `socks5h://`.

Then:

1. Open <https://api.ipify.org> in that Chrome window.
2. Confirm that its address matches the `curl` result above.
3. Open a Google search and complete the CAPTCHA, if one is offered.
4. Avoid rapid follow-up requests and wait briefly for the challenge state to
   settle.
5. Test the engine from SearXNG with a Google-only query such as `!go test`.

Use a disposable browser profile and do not sign in to a personal Google
account. SearXNG does not inherit Chrome's cookies, browser fingerprint, or
CAPTCHA token. Manual completion can only help when Google relaxes restrictions
on the shared egress IP. If SearXNG is challenged again immediately, use a
different reputable egress IP, lower the query rate, or use a persistent
browser-backed custom engine. Tor and heavily shared datacenter proxies are
commonly challenged and are poor choices for this purpose.

