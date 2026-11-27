## SUNAT PDT (e.g. PDT 0616) via Wine

Requires `_custom.gaming.utils.enable = true` (provides the `sunat-pdt` CLI backed by pure 32-bit Wayland `winePackages.stableFull`, a **SUNAT PDT** `.desktop` entry, and `winetricks`).

### First-time setup (fresh NixOS install)

```bash
sunat-pdt setup
```

This downloads `Integrador.exe`, `4tacat.exe` (PDT 0616), and `act_UIT.exe` from https://www2.sunat.gob.pe/pdt/pdtdown/independientes/independientes.htm, initializes a 32-bit Wayland prefix at `~/.wine-sunat32` (`WINEARCH=win32`, `vb6run`, `vcrun6`, `jet40`, `mdac28`, `winxp`, and Peru regional settings), runs the InstallShield wizards, registers the SUNAT OCX/DAO DLLs in `system32`, and enables native VB6 `oleaut32`/`olepro32`.

> **Note:** Keep the default `C:\SUNATPDT` path in the InstallShield wizards. If `Integrador.exe` hangs at **100%** after copying files, press **Enter** in the terminal to kill it and continue automatically.

### Daily usage

Launch from your app launcher (**SUNAT PDT**) or terminal (default login: `ADMINIST` / `ADMINIST`):

```bash
sunat-pdt
```

### Other commands

```bash
# Install another SUNAT PDT module (uses builtin oleaut32 so InstallShield doesn't crash)
sunat-pdt install ~/Downloads/other_pdt.exe

# Download and apply the latest UIT table
sunat-pdt update-uit

# Kill stuck Wine processes in ~/.wine-sunat32
sunat-pdt kill
```
