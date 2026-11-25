# shellcheck shell=bash
set -euo pipefail

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-sunat}"
DOWNLOAD_DIR="${SUNAT_PDT_DOWNLOAD_DIR:-$HOME/Downloads/sunat-pdt}"
PDT_DIR="$WINEPREFIX/drive_c/SUNATPDT"
WINE_BIN="$(command -v wine)"

INTEGRADOR_URL="https://www2.sunat.gob.pe/pdt/pdtdown/integrador/version11/Integrador.exe"
PDT0616_URL="https://www2.sunat.gob.pe/pdt/pdtdown/independientes/0616/4tacat.exe"
UIT_URL="https://www2.sunat.gob.pe/pdt/pdtdown/actualizaUIT/act_UIT.exe"

usage() {
  cat <<'EOF'
Usage: sunat-pdt [command]

Commands:
  (none), launch     Launch SUNAT PDT (pdt00.exe)
  setup              Download installers, initialize Wine prefix, install Integrador + PDT 0616 + UIT
  install <file.exe> Install an additional SUNAT PDT .exe module into the prefix
  update-uit         Download and install the latest SUNAT UIT updater
  kill               Stop all running Wine processes in the SUNAT prefix
  help               Show this help message
EOF
}

init_prefix() {
  echo "==> Initializing Wine prefix at $WINEPREFIX..."
  WINEDLLOVERRIDES="mscoree,mshtml=" wineboot --init
  wineserver -w || true

  echo "==> Installing VB6/VC6 runtimes and switching to Windows XP..."
  WINE="$WINE_BIN" WINE64="$WINE_BIN" winetricks -q vb6run vcrun6 winxp

  echo "==> Configuring Peru regional settings for SUNAT PDT..."
  WINEDEBUG=-all wine reg add "HKCU\\Control Panel\\International" /v sShortDate /t REG_SZ /d "dd/MM/yyyy" /f
  WINEDEBUG=-all wine reg add "HKCU\\Control Panel\\International" /v sTimeFormat /t REG_SZ /d "hh:mm:ss tt" /f
  WINEDEBUG=-all wine reg add "HKCU\\Control Panel\\International" /v sDecimal /t REG_SZ /d "." /f
  WINEDEBUG=-all wine reg add "HKCU\\Control Panel\\International" /v sThousand /t REG_SZ /d "," /f
  WINEDEBUG=-all wine reg add "HKCU\\Control Panel\\International" /v iNegCurr /t REG_SZ /d "2" /f
}

register_ocx() {
  echo "==> Registering SUNAT OCX/DAO libraries..."
  local dlls=(
    COMDLG32.OCX
    MSMASK32.OCX
    Mscomctl.ocx
    PDTFormaDePago.ocx
    PDTStatBar.ocx
    PDTUbigeo.ocx
    TABCTL32.OCX
    tdbg6.ocx
    dao350.dll
  )
  for dll in "${dlls[@]}"; do
    if [[ -f "$WINEPREFIX/drive_c/windows/syswow64/$dll" ]]; then
      WINEDEBUG=-all wine regsvr32 /s "C:\\windows\\syswow64\\$dll" || true
    fi
  done
}

enable_native_ole() {
  echo "==> Enabling native VB6 oleaut32/olepro32 overrides..."
  WINEDEBUG=-all wine reg add "HKCU\\Software\\Wine\\DllOverrides" /v oleaut32 /t REG_SZ /d "native,builtin" /f
  WINEDEBUG=-all wine reg add "HKCU\\Software\\Wine\\DllOverrides" /v olepro32 /t REG_SZ /d "native,builtin" /f
}

run_installer() {
  local exe="$1"
  local allow_enter_kill="${2:-false}"

  if [[ ! -f "$exe" ]]; then
    echo "Error: installer not found: $exe" >&2
    exit 1
  fi

  if [[ "$allow_enter_kill" == "true" ]]; then
    echo "    (If InstallShield hangs at 100%, press Enter here to kill it and continue.)"
    WINEDLLOVERRIDES="oleaut32,olepro32=b" wine "$exe" &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      if read -r -t 1 _; then
        wineserver -k || true
        break
      fi
    done
    wait "$pid" 2>/dev/null || true
  else
    WINEDLLOVERRIDES="oleaut32,olepro32=b" wine "$exe"
  fi
}

cmd_setup() {
  mkdir -p "$DOWNLOAD_DIR"

  echo "==> Downloading SUNAT installers into $DOWNLOAD_DIR..."
  [[ -f "$DOWNLOAD_DIR/Integrador.exe" ]] || curl -fL -o "$DOWNLOAD_DIR/Integrador.exe" "$INTEGRADOR_URL"
  [[ -f "$DOWNLOAD_DIR/4tacat.exe" ]] || curl -fL -o "$DOWNLOAD_DIR/4tacat.exe" "$PDT0616_URL"
  curl -fL -o "$DOWNLOAD_DIR/act_UIT.exe" "$UIT_URL"

  init_prefix

  echo "==> Running Módulo Integrador installer (keep default C:\\SUNATPDT path)..."
  run_installer "$DOWNLOAD_DIR/Integrador.exe" true

  register_ocx

  echo "==> Running PDT 0616 installer..."
  run_installer "$DOWNLOAD_DIR/4tacat.exe"

  echo "==> Running UIT updater..."
  run_installer "$DOWNLOAD_DIR/act_UIT.exe"

  enable_native_ole

  echo "==> Done! Launch with: sunat-pdt (default login: ADMINIST / ADMINIST)"
}

cmd_launch() {
  if [[ ! -f "$PDT_DIR/pdt00.exe" ]]; then
    echo "SUNAT PDT is not installed in $WINEPREFIX yet." >&2
    echo "Run: sunat-pdt setup" >&2
    exit 1
  fi
  cd "$PDT_DIR"
  exec wine pdt00.exe
}

cmd_update_uit() {
  mkdir -p "$DOWNLOAD_DIR"
  echo "==> Downloading latest UIT updater..."
  curl -fL -o "$DOWNLOAD_DIR/act_UIT.exe" "$UIT_URL"
  run_installer "$DOWNLOAD_DIR/act_UIT.exe"
  enable_native_ole
}

case "${1:-launch}" in
  launch)
    cmd_launch
    ;;
  setup)
    cmd_setup
    ;;
  install)
    if [[ $# -lt 2 ]]; then
      echo "Usage: sunat-pdt install <file.exe>" >&2
      exit 1
    fi
    run_installer "$2"
    enable_native_ole
    ;;
  update-uit)
    cmd_update_uit
    ;;
  kill)
    wineserver -k
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac
