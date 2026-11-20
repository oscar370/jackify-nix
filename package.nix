{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
  nix-update-script,
}:

let
  pname = "jackify";
  version = "0.8.1.3";

  src = fetchurl {
    url = "https://github.com/Omni-guides/Jackify/releases/download/v${version}/Jackify.AppImage";
    hash = "sha256-Z3T4Gu3WxnyMOO7kIF/BSXGJfNurmcZULTWCl4rzlTI=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
    # AppRun copies jackify-engine and jackify-game-downgrader into
    # ~/Jackify with `cp -r`. From the read-only Nix store the copies end
    # up read-only too, so the next copy (or `rm -rf ~/Jackify`) fails with
    # "Permission denied", and the engine cannot write next to itself.
    # Make the copies user-writable and replace them cleanly.
    postExtract = ''
      chmod u+w $out/AppRun
      substituteInPlace $out/AppRun \
        --replace-fail 'cp -r "$ENGINE_SOURCE_DIR" "$JACKIFY_HOME/"' \
          'chmod -R u+w "$JACKIFY_HOME/jackify-engine" 2>/dev/null; rm -rf "$JACKIFY_HOME/jackify-engine"; cp -r "$ENGINE_SOURCE_DIR" "$JACKIFY_HOME/"; chmod -R u+w "$JACKIFY_HOME/jackify-engine"' \
        --replace-fail 'rm -rf "$JACKIFY_HOME/jackify-game-downgrader"' \
          'chmod -R u+w "$JACKIFY_HOME/jackify-game-downgrader" 2>/dev/null; rm -rf "$JACKIFY_HOME/jackify-game-downgrader"' \
        --replace-fail 'cp -r "$DOWNGRADER_SOURCE_DIR" "$JACKIFY_HOME/"' \
          'cp -r "$DOWNGRADER_SOURCE_DIR" "$JACKIFY_HOME/"; chmod -R u+w "$JACKIFY_HOME/jackify-game-downgrader"'
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  # The AppImage does not bundle a Python interpreter: AppRun looks up
  # `python3` on PATH and runs the bundled site-packages (built for 3.10,
  # but PySide6/shiboken6/psutil are abi3 and the few cpython-310 modules
  # have pure-Python fallbacks) with `python3 -S`.
  extraPkgs = pkgs: [ pkgs.python3 ];

  # Jackify runs Proton's wine directly (winetricks, registry fixes) from
  # inside this FHS env; without the 32-bit side it fails with
  # "/lib/ld-linux.so.2: could not open".
  multiArch = true;

  # Jackify reads $APPIMAGE to:
  #  - write ~/.local/share/applications/com.jackify.app.desktop
  #    (handler for jackify:// OAuth callbacks and nxm:// links)
  #  - decide whether it can self-update (requires a writable file)
  # Pointing it at this wrapper makes the protocol handlers launch something
  # that actually runs on NixOS, and disables the self-updater automatically
  # because the Nix store is read-only.
  extraInstallCommands = ''
    source ${makeWrapper}/nix-support/setup-hook
    wrapProgram $out/bin/${pname} --set APPIMAGE $out/bin/${pname}

    install -Dm444 ${appimageContents}/usr/share/applications/com.jackify.app.desktop \
      -t $out/share/applications
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Wabbajack modlist installer and configurator for Linux";
    homepage = "https://github.com/Omni-guides/Jackify";
    changelog = "https://github.com/Omni-guides/Jackify/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "jackify";
    maintainers = [ "oscar370" ];
  };
}
