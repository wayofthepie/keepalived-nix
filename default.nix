{ pkgs ?
    if builtins.currentSystem != "aarch64-multiplatform" then (import <nixpkgs> {}).pkgsCross.aarch64-multiplatform
    else import <nixpkgs> {},
  version ? "0.0.0"
}:

let
    keepalived = with pkgs; stdenv.mkDerivation {
    name = "keepalived";
    src = fetchurl {
      url = "https://www.keepalived.org/software/keepalived-2.2.8.tar.gz";
      sha256 = "1dhvg9x976k4nnygxyv2gr55jfd88459kgiiqva9bwvl56v2x245";
    };
    buildInputs = [ pkgsStatic.openssl ];
    preBuild = ''
      makeFlagsArray=(
                      CFLAGS="-static"
                      LDFLAGS="-L${glibc.static}/lib")
    '';
    installPhase = ''
      ./configure --disable-dynamic-linking
      make
      mkdir -p $out/bin
      cp bin/keepalived $out/bin/keepalived
      ${pkgs.upx}/bin/upx $out/bin/keepalived
      ls -la $out/bin
    '';
  };

  keepalivedImage = with pkgs; dockerTools.buildImage {
    name = "wayofthepie/keepalived";
    tag = "${version}";
    copyToRoot = buildEnv {
      name = "image-root";
      paths = [ "${keepalived}" ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Cmd = [ "/bin/keepalived" ];
    };
  };
in keepalivedImage
