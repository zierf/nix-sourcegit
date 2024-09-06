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
  version = "8.28";
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
    url = "https://github.com/sourcegit-scm/sourcegit/releases/download/v${version}/sourcegit-${version}.linux.amd64.AppImage";
    hash = "sha256-YEAr4mgwnnnIFUN4+AFa4V4gipdEnuD/M72TF6HNQ4s=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

  # https://github.com/sourcegit-scm/sourcegit-theme
  themes = fetchFromGitHub {
    owner = "sourcegit-scm";
    repo = "sourcegit-theme";
    rev = "474dfa4a0bfbf478ca4e5bc81318e1b17518159d";
    sha256 = "sha256-oJhAGCFXkmH95jfkf9yZALzob5XuNij44lrTHbuNATI=";
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

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,themes,share/icons/hicolor/256x256/apps}
    cp -rv ${appimageContents}/opt/sourcegit/*.so $out/lib
    cp -rv ${appimageContents}/opt/sourcegit/${exeName} $out/bin
    cp -rv ${appimageContents}/com.sourcegit_scm.SourceGit.png $out/share/icons/hicolor/256x256/apps/${exeName}.png
    cp -rv ${themes}/themes/*.json $out/themes

    echo "LD_LIBRARY_PATH = ${libraryPath}"
    echo "PATH = ${binaryPath}"

    runHook postInstall
  '';

  # PATH has to be prefixed to find system executables for filemanager, terminal and difftools (like VSCode)
  postFixup = ''
    wrapProgram $out/bin/${exeName} \
      --set LD_LIBRARY_PATH ${libraryPath} \
      --prefix PATH : ${binaryPath}
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
