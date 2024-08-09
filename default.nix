# $> nix-build
# { pkgs ? import <nixpkgs> { } }:

# $> nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
{ lib
, stdenvNoCC
, appimageTools
, copyDesktopItems
, fetchFromGitHub
, fetchurl
, fontconfig
, git
, git-credential-manager
, glibc
, gnupg
, icu
, makeDesktopItem
, makeWrapper
, openssh
, xdg-utils
}:

let
  pname = "sourcegit";
  version = "8.24";
  exeName = "${pname}";

  dependencies = [
    fontconfig
    git
    git-credential-manager
    glibc
    gnupg
    icu
    openssh
    xdg-utils
  ];

  # https://github.com/sourcegit-scm/sourcegit
  src = fetchurl {
    url = "https://github.com/sourcegit-scm/sourcegit/releases/download/v${version}/sourcegit-${version}.linux.x86_64.AppImage";
    hash = "sha256-FozCsk7HwCXKQwC/+72j1IM8d3G6rvNCaxoTePad10s=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

  # https://github.com/sourcegit-scm/sourcegit-theme
  themes = fetchFromGitHub {
    owner = "sourcegit-scm";
    repo = "sourcegit-theme";
    rev = "09f67cd29124717ae7ce5d70ae436ba505fdd459";
    sha256 = "sha256-netHt8xbAK4K7Hzi9booV0uldii8IYNBHRgMLEojE8w=";
  };
in
stdenvNoCC.mkDerivation rec {
  inherit version pname;
  src = appimageContents;

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [ ] ++ dependencies;

  libraryPath = lib.makeLibraryPath ([
    "$out"
  ] ++ dependencies);

  binaryPath = lib.makeBinPath ([
    "$out"
  ] ++ dependencies);

  desktopItems = [
    (makeDesktopItem {
      name = "SourceGit";
      desktopName = "SourceGit";
      comment = "Open-source GUI client for git users";
      categories = [ "Development" ];
      exec = "${exeName} %U";
      icon = "${exeName}";
      terminal = false;
      type = "Application";
    })
  ];

  # preBuild = ''
  #   addAutoPatchelfSearchPath ${pkgs.icu}/lib
  # '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,themes,/share/icons/hicolor/256x256/apps}
    cp -rv ${appimageContents}/usr/bin/*.so $out/lib
    cp -rv ${appimageContents}/usr/bin/${exeName} $out/bin
    cp -rv ${appimageContents}/com.sourcegit-scm.SourceGit.png $out/share/icons/hicolor/256x256/apps/${exeName}.png
    cp -rv ${themes}/themes/*.json $out/themes

    echo "LD_LIBRARY_PATH = ${libraryPath}"
    echo "PATH = ${binaryPath}"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/${exeName} \
      --set LD_LIBRARY_PATH ${libraryPath} \
      --prefix PATH ${binaryPath}
  '';

  meta = with lib; {
    description = "Opensource Git GUI client";
    homepage = "https://github.com/sourcegit-scm/sourcegit";
    changelog = "https://github.com/sourcegit-scm/sourcegit/releases/tag/v${version}";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ stdenv.lib.maintainer "Florian Zier <9168602+zierf@users.noreply.github.com>" ];
  };
}
