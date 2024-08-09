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

  # https://github.com/sourcegit-scm/sourcegit
  src = pkgs.fetchurl {
    url = "https://github.com/sourcegit-scm/sourcegit/releases/download/v${version}/sourcegit-${version}.linux.x86_64.AppImage";
    hash = "sha256-FozCsk7HwCXKQwC/+72j1IM8d3G6rvNCaxoTePad10s=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  # https://github.com/sourcegit-scm/sourcegit-theme
  themes = pkgs.fetchFromGitHub {
    owner = "sourcegit-scm";
    repo = "sourcegit-theme";
    rev = "09f67cd29124717ae7ce5d70ae436ba505fdd459";
    sha256 = "sha256-netHt8xbAK4K7Hzi9booV0uldii8IYNBHRgMLEojE8w=";
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

  # preBuild = ''
  #   addAutoPatchelfSearchPath ${pkgs.icu}/lib
  # '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,themes}
    cp -rv ${appimageContents}/usr/bin/*.so $out/lib
    cp -rv ${appimageContents}/usr/bin/${exeName} $out/bin
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

  meta = with pkgs.lib; {
    description = "Opensource Git GUI client";
    homepage = "https://github.com/sourcegit-scm/sourcegit";
    changelog = "https://github.com/sourcegit-scm/sourcegit/releases/tag/v${version}";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ stdenv.lib.maintainer "Florian Zier <9168602+zierf@users.noreply.github.com>" ];
  };
}
