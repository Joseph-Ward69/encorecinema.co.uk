#!/bin/sh
# Builds the site: wraps each src/<page>.html in the shared header and footer.
# The first line of each source file is: Title | Description | nav key (home, privacy or blank)
set -e
cd "$(dirname "$0")"
LOGO=$(cat assets/logo.svg | sed 's|<svg |<svg aria-hidden="true" |')
# form-url: the Formspree endpoint the register-interest form posts to.
FORM=$(tr -d '\r\n ' < form-url 2>/dev/null)
for src in src/*.html; do
  case "$(basename "$src")" in _*) continue;; esac
  name=$(basename "$src")
  meta=$(head -n 1 "$src")
  title=$(echo "$meta" | cut -d'|' -f1 | sed 's/ *$//')
  desc=$(echo "$meta" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')
  key=$(echo "$meta" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//')
  cur() { [ "$key" = "$1" ] && printf ' aria-current="page"'; }
  {
    cat <<EOF
<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<meta name="description" content="$desc">
<meta property="og:title" content="$title">
<meta property="og:description" content="$desc">
<meta property="og:image" content="https://encorecinema.co.uk/assets/shots/tv-films.jpg">
<link rel="icon" href="/assets/logo.svg" type="image/svg+xml">
<link rel="stylesheet" href="/assets/site.css">
<link rel="stylesheet" href="/assets/cinema.css">
</head>
<body>
<header class="site"><div class="wrap">
  <a class="brand" href="/">$LOGO<span>Encore Cinema&trade;</span></a>
  <nav class="main">
    <a href="/"$(cur home)>Home</a>
    <a href="/#features">Features</a>
    <a href="/#how">How it works</a>
    <a href="/#questions">Questions</a>
    <a href="/#interest">Register interest</a>
  </nav>
</div></header>
<main>
EOF
    tail -n +2 "$src"
    cat <<EOF
</main>
<footer class="site"><div class="wrap">
  <div>&copy; 2026 Encore Audio Ltd. Encore Cinema&trade; is made by Encore Audio Ltd, the makers of Encore Audio.<br>
  Encore Audio Ltd, registered in England and Wales, company number 17539933.<br>
  Registered office: 128 City Road, London EC1V 2NX.<br>
  <a href="mailto:contact@encoreaudio.co.uk">contact@encoreaudio.co.uk</a><br>
  <span class="small-print">Dolby, Dolby Vision, Dolby Atmos and Dolby TrueHD are trade marks of Dolby Laboratories. Google TV and Android TV are trade marks of
  Google LLC. Fire TV is a trade mark of Amazon.com, Inc. Encore Cinema isn't endorsed by any of them.</span></div>
  <nav><a href="https://encoreaudio.co.uk/">Encore Audio, for your music</a><a href="/#interest">Register interest</a><a href="/privacy.html">Privacy</a></nav>
</div></footer>
<script src="/assets/forms.js" defer></script>
<script src="/assets/motion.js" defer></script>
</body>
</html>
EOF
  } | sed "s|FORM_URL|$FORM|g" > "$name"
done
echo "Built: $(ls src | grep -v '^_' | tr '\n' ' ')"
