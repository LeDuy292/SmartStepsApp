#!/usr/bin/env bash
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.vercel/flutter}"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
BASE_HREF="${VERCEL_BASE_HREF:-/}"

if [[ "$BASE_HREF" != /* ]]; then
  BASE_HREF="/$BASE_HREF"
fi

if [[ "$BASE_HREF" != */ ]]; then
  BASE_HREF="$BASE_HREF/"
fi

if [[ ! -x "$FLUTTER_BIN" ]]; then
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter config --enable-web
flutter pub get

# Inject Google Analytics 4 (GA4) script if GA_MEASUREMENT_ID environment variable is provided
if [[ -n "${GA_MEASUREMENT_ID:-}" ]]; then
  echo "Injecting Google Analytics 4 (GA4) script into web/index.html..."
  node -e '
    const fs = require("fs");
    const id = process.env.GA_MEASUREMENT_ID;
    let html = fs.readFileSync("web/index.html", "utf8");
    const gaScript = `<!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=${id}"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag("js", new Date());
    gtag("config", "${id}");
  </script>`;
    html = html.replace("<!-- GA4_SCRIPT_PLACEHOLDER -->", gaScript);
    fs.writeFileSync("web/index.html", html, "utf8");
  '
else
  echo "GA_MEASUREMENT_ID environment variable is not set. Skipping GA4 script injection."
fi

flutter build web   --release   --base-href "$BASE_HREF"   --dart-define=FLUTTER_WEB_AUTO_DETECT=false
