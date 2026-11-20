# jackify-nix

[Jackify](https://github.com/Omni-guides/Jackify) (Wabbajack modlist installer for Linux) packaged for NixOS from the upstream AppImage.

Unofficial, community-maintained. Upstream does not support NixOS ([Omni-guides/Jackify#74](https://github.com/Omni-guides/Jackify/issues/74)); please report packaging problems here, not upstream.

## Usage

Run it without installing anything:

```sh
nix run github:oscar370/jackify-nix
```

It stays in the Nix store until the next `nix-collect-garbage`.

## Requirements on the host

- Steam (`programs.steam.enable = true;`) and Protontricks available.
- A Proton version Jackify can detect: Proton Experimental / Proton 9+ installed from Steam, or GE-Proton in `~/.local/share/Steam/compatibilitytools.d`.

  Jackify only recognises GE-Proton folders named `GE-ProtonX-Y` (it parses the version from the folder name), so a link named just `GE-Proton` is ignored. With Home Manager:

  ```nix
  xdg.dataFile."Steam/compatibilitytools.d/${pkgs.proton-ge-bin.version}".source =
    pkgs.proton-ge-bin.steamcompattool;
  ```

  Steam is unaffected by the folder name: nixpkgs' `proton-ge-bin` always registers itself as `GE-Proton`, which is also the name Jackify writes to Steam's config.

## What Jackify writes to your home

Independent of this package, Jackify itself creates:

- `~/.local/share/applications/com.jackify.app.desktop` and `~/.local/share/icons/hicolor/256x256/apps/com.jackify.app.png`
- entries in `~/.config/mimeapps.list` making it the handler for `jackify://` (Nexus OAuth) **and `nxm://`** (this replaces any other mod manager's nxm handler)
- `~/Jackify/`: logs, a copy of jackify-engine, downloaded tools
- `~/.config/jackify/`: configuration

To clean up after use:

```sh
rm -f ~/.local/share/applications/com.jackify.app.desktop \
      ~/.local/share/icons/hicolor/256x256/apps/com.jackify.app.png
sed -i -E '/^x-scheme-handler\/(jackify|nxm)=com\.jackify\.app\.desktop;?$/d' ~/.config/mimeapps.list
nix shell nixpkgs#desktop-file-utils -c update-desktop-database ~/.local/share/applications
rm -rf ~/Jackify ~/.config/jackify
```

## Packaging notes

- The AppImage ships no Python interpreter; `python3` is added to the FHS environment.
- AppRun's copy of jackify-engine / jackify-game-downgrader into `~/Jackify` is patched to make the copies user-writable (otherwise they inherit the store's read-only permissions).
- `APPIMAGE` is set to the wrapper, so the protocol handlers Jackify registers point to an executable path, and the built-in self-updater disables itself (the store is not writable).
- Updates: `nix-update --flake jackify`.