#!/bin/bash
set -e

if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  FIRST_ANDROID=$(perl .github/scripts/lib/parse_presets.pl all_android | head -1)
  DEBUG_KEYSTORE_PATH=$(perl .github/scripts/lib/parse_presets.pl keystore "$FIRST_ANDROID" debug)
  RELEASE_KEYSTORE_PATH=$(perl .github/scripts/lib/parse_presets.pl keystore "$FIRST_ANDROID" release)
else
  DEBUG_KEYSTORE_PATH=$(perl .github/scripts/lib/parse_presets.pl keystore "$PRESET_NAME" debug)
  RELEASE_KEYSTORE_PATH=$(perl .github/scripts/lib/parse_presets.pl keystore "$PRESET_NAME" release)
fi

DEBUG_KEYSTORE_PATH=${DEBUG_KEYSTORE_PATH:-"debug.keystore"}

echo "DEBUG_KEYSTORE_PATH=$DEBUG_KEYSTORE_PATH" >>"$GITHUB_ENV"
echo "RELEASE_KEYSTORE_PATH=$RELEASE_KEYSTORE_PATH" >>"$GITHUB_ENV"

mkdir -p "$(dirname "$RELEASE_KEYSTORE_PATH")"
mkdir -p "$(dirname "$DEBUG_KEYSTORE_PATH")"

if [[ -n "$RELEASE_KEYSTORE_BASE64" ]]; then
  echo ">>> Decoding existing keystore..."
  echo "$RELEASE_KEYSTORE_BASE64" | base64 --decode >"$RELEASE_KEYSTORE_PATH"

elif [[ "$DEBUG" == "false" ]]; then
  echo ">>> Generating release keystore..."

  rm -f "$RELEASE_KEYSTORE_PATH"

  DNAME="CN=${CERT_CN}"
  [ -n "$ORG" ] && DNAME="$DNAME, O=$ORG"
  [ -n "$ORG_UNIT" ] && DNAME="$DNAME, OU=$ORG_UNIT"
  [ -n "$CITY" ] && DNAME="$DNAME, L=$CITY"
  [ -n "$STATE" ] && DNAME="$DNAME, ST=$STATE"
  [ -n "$COUNTRY" ] && DNAME="$DNAME, C=$COUNTRY"

  keytool -genkey -v -noprompt \
    -keystore "$RELEASE_KEYSTORE_PATH" \
    -alias "$KEYSTORE_USER" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -dname "$DNAME" \
    -keyalg RSA -keysize 2048 -validity 10000
fi

if [[ ! -f "$DEBUG_KEYSTORE_PATH" ]]; then
  echo ">>> Generating debug keystore..."
  keytool -genkey -v -noprompt \
    -keystore "$DEBUG_KEYSTORE_PATH" \
    -alias androiddebugkey \
    -storepass android \
    -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 9000
fi
