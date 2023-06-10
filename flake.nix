{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.aasdk-repo.url = "github:KiruyaMomochi/aasdk/development";

  outputs = { self, nixpkgs, flake-utils, aasdk-repo }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        aasdk = aasdk-repo.packages.${system}.default;
      in
      {
        packages.default = pkgs.libsForQt5.callPackage
          ({ lib
           , stdenv
           , qt5
           , pulseaudio
           , gst_all_1
           , wrapQtAppsHook
           , cmake
           , boost
           , protobuf
           , libusb
           , rtaudio
           , openssl
           , taglib
           , libuuid
           , gpsd
           , aasdk
           }:
            stdenv.mkDerivation {
              pname = "openauto";
              version = "craftshaft-ng";

              src = ./.;

              nativeBuildInputs = [
                cmake
                wrapQtAppsHook
                boost

                # CMake only finds these dependencies when they are in nativeBuildInputs
                # THIS IS A BUG FROM CMakeLists.txt
                protobuf
                rtaudio
                taglib
                libuuid
                libusb
                gpsd
                qt5.qtbase
                qt5.qtmultimedia
                qt5.qtconnectivity
              ];

              buildInptus = [
                pulseaudio
                gst_all_1.gst-libav
                gst_all_1.gst-plugins-bad
                openssl
                aasdk
              ];

              postPatch = ''
                echo 'Copying files...'
                cp -r ${aasdk}/include/aasdk ./include/f1x/
                cp -r ${aasdk}/include/aasdk_proto ./include/
              '';

              cmakeFlags = [
                "-DCMAKE_BUILD_TYPE=Release"
                "-DRPI3_BUILD=FALSE"
                "-DAASDK_INCLUDE_DIRS=${aasdk}/include/"
                "-DAASDK_LIBRARIES=${aasdk}/lib/libaasdk.so"
                "-DAASDK_PROTO_INCLUDE_DIRS=${aasdk}/include/"
                "-DAASDK_PROTO_LIBRARIES=${aasdk}/lib/libaasdk_proto.so"
              ];
            }
          )
          { inherit aasdk; };

        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            cmake
            boost
            protobuf
            libusb
            rtaudio
            openssl
            taglib
            libuuid # blkid
            gpsd
            aasdk
          ]) ++ (with pkgs.qt5; [
            qtmultimedia
            qtbase
            qtconnectivity
          ]);
        };
      });
}
