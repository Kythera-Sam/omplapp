{
  description = "omplapp dev shell with all dependencies";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};

        # Use Python 3.11 which still has distutils
        python = pkgs.python311;

        # Override boost to enable Python support with 3.11
        boostWithPython = pkgs.boost.override {
          enablePython = true;
          python = python;
        };

        # Create a Python environment with all required packages
        pythonEnv = python.withPackages (ps:
          with ps; [
            pip
            setuptools
            numpy
            pyyaml
            pyqt5
            pyopengl
            pygccxml
          ]);
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build tools
            ninja
            cmake
            pkg-config
            gcc
            clang

            # Core OMPL dependencies with Python-enabled boost
            boostWithPython
            eigen
            assimp
            libccd
            fcl

            # Graphics/GUI dependencies
            libGL
            xorg.libX11
            xorg.libXext
            libsForQt5.qt5.qtbase
            libsForQt5.qt5.qttools

            # Additional X11/xcb libraries for Qt
            pkgs.xorg.libxcb
            pkgs.xorg.xcbutil
            pkgs.xorg.xcbutilwm
            pkgs.xorg.xcbutilimage
            pkgs.xorg.xcbutilkeysyms
            pkgs.xorg.xcbutilrenderutil
            pkgs.libxkbcommon
            pkgs.dbus
            pkgs.fontconfig
            pkgs.freetype

            # Python environment
            pythonEnv

            # Binding generator backend
            castxml

            # Optional dependencies
            octomap
            yaml-cpp
            doxygen
            graphviz
            pypy3
            flann

            # Useful development tools
            gdb
            lldb
            valgrind
          ];

          shellHook = ''
                      # Create a local directory for pyplusplus
                      export PIP_PREFIX="$(pwd)/.pip-packages"
                      export PYTHONPATH="$PIP_PREFIX/lib/python3.11/site-packages:$PYTHONPATH"
                      export PATH="$PIP_PREFIX/bin:$PATH"

                      # Install pyplusplus if not already installed
                      if [ ! -d "$PIP_PREFIX/lib/python3.11/site-packages/pyplusplus" ]; then
                        echo "Installing pyplusplus to $PIP_PREFIX..."
                        pip install --prefix="$PIP_PREFIX" --no-warn-script-location pyplusplus
                      fi

                      # Help CMake find packages in Nix store
                      export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "lib" "pkgconfig" [
              boostWithPython
              pkgs.eigen
              pkgs.assimp
              pkgs.libccd
              pkgs.fcl
              pkgs.libGL
            ]}:$PKG_CONFIG_PATH"

            export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.libsForQt5.qt5.qtbase.bin}/lib/qt-${pkgs.libsForQt5.qt5.qtbase.version}/plugins"
            export QT_PLUGIN_PATH="$QT_QPA_PLATFORM_PLUGIN_PATH"

            # Additional Qt/X11 libraries that may be needed
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.libsForQt5.qt5.qtbase
              pkgs.xorg.libX11
              pkgs.xorg.libxcb
              pkgs.xorg.xcbutil
              pkgs.xorg.xcbutilwm
              pkgs.xorg.xcbutilimage
              pkgs.xorg.xcbutilkeysyms
              pkgs.xorg.xcbutilrenderutil
              pkgs.libGL
              pkgs.glib
            ]}:$LD_LIBRARY_PATH"

                      # Help CMake find Boost.Python (Python 3.11 version)
                      export Boost_DIR="${boostWithPython}/lib/cmake/Boost-1.87.0"

                      echo "OMPL App development environment ready!"
                      echo "Boost with Python: ${boostWithPython}"
                      echo "Python: $(which python) [$(python --version)]"
                      echo "CastXML: $(which castxml)"
                      echo "pyplusplus installed to: $PIP_PREFIX"
          '';
        };
      }
    );
}
