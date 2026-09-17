#!/usr/bin/env bash
set -euo pipefail

# A cold cache must not depend on dispatching a separate workflow.
mkdir -p resources
geo_commit=6d5ea402b627e83569a6dd7cf16d13c80b2788a3
for entry in \
  'geoip.dat 45325fee1555c8bf04115100694ce8429b88c9bb3b3548abcfd236a1c8ea146f' \
  'geosite.dat cc45cbe96e4f3160260232b64039807f73b10a7fbae62c7dfcd83bed7ba7a233'; do
  read -r filename digest <<< "$entry"
  if ! echo "$digest  resources/$filename" | sha256sum -c --status 2>/dev/null; then
    curl -fL --retry 3 "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/$geo_commit/$filename" \
      -o "resources/$filename"
  fi
  echo "$digest  resources/$filename" | sha256sum -c
done

if [[ ${1:-} == --wintun ]]; then
  if [[ ! -s resources/wintun/LICENSE.txt || ! -s resources/wintun/bin/amd64/wintun.dll || \
        ! -s resources/wintun/bin/x86/wintun.dll || ! -s resources/wintun/bin/arm64/wintun.dll ]]; then
    temporary=$(mktemp)
    trap 'rm -f "$temporary"' EXIT
    curl -fL --retry 3 https://www.wintun.net/builds/wintun-0.14.1.zip -o "$temporary"
    echo "07c256185d6ee3652e09fa55c0b673e2624b565e02c4b9091c79ca7d2f24ef51  $temporary" | sha256sum -c
    unzip -oq "$temporary" -d resources
  fi
  for architecture in amd64 x86 arm64; do
    test -s "resources/wintun/bin/$architecture/wintun.dll"
  done
  test -s resources/wintun/LICENSE.txt
fi
