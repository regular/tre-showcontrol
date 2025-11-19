{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    tre-cli-tools = {
      url = "github:regular/tre-cli-tools-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, systems, nixpkgs, ... }@inputs: let
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f rec {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
      pkg_deps = with pkgs; [
        bash
        iputils
        systemd
      ];
      path = pkgs.lib.makeBinPath pkg_deps;
    });
  in {
    nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.default
        {
          services.tre-showcontrol = {
            enable = true;
          };
        }
      ];
    };
    nixosModules.default = (import ./service.nix) self;
    packages = eachSystem ( { pkgs, system, path, ... }: let 
      cli-tools = inputs.tre-cli-tools.packages.${system}.default;
      extraModulePath = "${cli-tools}/lib/node_modules/tre-cli-tools/node_modules";
      version = "2.0.0";
      pname = "tre-showcontrol";
      meta = {
        description = "Shutdown when a certain machine does nit respond to pings anymore";
        mainProgram = "tre-showcontrol";
        maintainers = [ "jan@lagomorph.de" ];
      };
    in {
      default = pkgs.buildNpmPackage rec {
        inherit version pname meta;

        dontNpmBuild = true;
        makeCacheWritable = true;
        npmFlags = [ "--omit=dev" "--omit=optional"];

        src = ./.;

        npmDepsHash = "sha256-MhJK1fblDY7Xvy4WK+mf3HRr1b2T7BKIRoAql43Mvhs=";
        postBuild = ''
          mkdir -p $out/lib/node_modules/${pname}
          cat <<EOF > $out/lib/node_modules/${pname}/extra-modules-path.js
          process.env.NODE_PATH += ':${extraModulePath}' 
          require('module').Module._initPaths()
          EOF
          '';

        nativeBuildInputs = [ pkgs.makeWrapper ];
        postInstall = ''
          wrapProgram $out/bin/tre-showcontrol \
          --set SHELL ${pkgs.bash}/bin/bash \
          --set PATH ${path}
          '';
      };
    });

    devShells = eachSystem ( { pkgs, system, ... }: {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs
          pkgs.python3
        ];
      };
    });
  };
}
