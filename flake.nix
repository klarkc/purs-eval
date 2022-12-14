{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      npmlock2nix.url = "github:nix-community/npmlock2nix";
      npmlock2nix.flake = false;
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      utils.url = "github:ursi/flake-utils";
    };

  outputs = { utils, ... }@inputs:
    utils.apply-systems
      {
        inherit inputs;
        # Limited by ps-tools
        systems = [ "x86_64-linux" "x86_64-darwin" ];
      }
      ({ pkgs, system, ... }:
        let
          npm = import inputs.npmlock2nix { inherit pkgs; };
          ps-tools = inputs.ps-tools.legacyPackages.${system};
          purs-nix = inputs.purs-nix { inherit system; };
          ps =
            purs-nix.purs
              {
                dir = ./.;

                dependencies =
                  with purs-nix.ps-pkgs;
                  [
                    prelude
                    debug
                    aff
                    affjax-node
                    argonaut-codecs
                    argonaut-generic
                    effect
                    httpure
                    node-buffer
                    node-process
                    node-streams-aff
                    test-unit
                    parsing
                  ];

                foreign."Affjax.Node".node_modules = npm.v2.node_modules { src = ./.; } + /node_modules;

              };
        in
        with ps;
        rec {
          apps.default = {
            type = "app";
            program = "${packages.default}/bin/purs-eval";
          };

          packages.default = modules.Main.app { name = "purs-eval"; };

          checks.test = test.check { };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              (ps.command { })
              ps-tools.for-0_15.purescript-language-server
              purs-nix.esbuild
              purs-nix.purescript
            ];
          };
        }
      );
}
