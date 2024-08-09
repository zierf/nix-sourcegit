{ pkgs ? import <nixpkgs> { } }:

let
  pname = "sourcegit";
  version = "8.24";
  exeName = "${pname}";

  dependencies = with pkgs; [
    fontconfig
    git
    git-credential-manager
    glibc
    gnupg
    icu
    openssh
    xdg-utils
  ];

  src = pkgs.fetchurl {
    url = "https://github.com/sourcegit-scm/sourcegit/releases/download/v${version}/sourcegit-${version}.linux.x86_64.AppImage";
    hash = "sha256-FozCsk7HwCXKQwC/+72j1IM8d3G6rvNCaxoTePad10s=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };
in
pkgs.stdenvNoCC.mkDerivation rec {
  inherit version pname;
  src = appimageContents;

  nativeBuildInputs = with pkgs; [
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = with pkgs; [ ] ++ dependencies;

  libraryPath = pkgs.lib.makeLibraryPath ([
    "$out"
  ] ++ dependencies);

  binaryPath = pkgs.lib.makeBinPath ([
    "$out"
  ] ++ dependencies);

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "SourceGit";
      desktopName = "SourceGit";
      comment = "Open-source GUI client for git users";
      categories = [ "Development" ];
      exec = "${appimageContents}/usr/bin/${exeName} %U";
      icon = "${appimageContents}/com.sourcegit-scm.SourceGit.png";
      terminal = false;
      type = "Application";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}
    cp -rv usr/bin/*.so $out/lib
    cp -rv usr/bin/${exeName} $out/bin

    echo "${libraryPath}"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/${exeName} \
      --set LD_LIBRARY_PATH ${libraryPath} \
      --prefix PATH ${binaryPath}
  '';

  meta = with pkgs.lib; {
    description = "Opensource Git GUI client";
    homepage = "https://github.com/sourcegit-scm/sourcegit";
    changelog = "https://github.com/sourcegit-scm/sourcegit/releases/tag/v${version}";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ stdenv.lib.maintainer "Florian Zier <9168602+zierf@users.noreply.github.com>" ];
  };
}
