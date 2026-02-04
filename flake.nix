{
  description = "Hub and Spoke Demo: Plumber R API with NixOS + OpenTofu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix2container, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
        overlays = [
          (final: prev: {
            rEnv = prev.rWrapper.override {
              packages = with prev.rPackages; [
                plumber
                jsonlite
              ];
            };
          })
        ];
      };
      n2c = nix2container.packages.${system}.nix2container;
    in
    {
      packages.${system} = {
        # --- Container for Cloud Run ---
        container = n2c.buildImage {
          name = "hubspoke-demo";
          tag = self.shortRev or "latest";
          copyToRoot = pkgs.buildEnv {
            name = "container-root";
            paths = [ 
              pkgs.rEnv
              pkgs.curl  # For health checks
              # Copy plumber.R to /app in container
              (pkgs.runCommand "app-files" {} ''
                mkdir -p $out/app
                cp ${./src/plumber.R} $out/app/plumber.R
              '')
            ];
          };
          
          config = {
            Cmd = [ 
              "Rscript" 
              "-e" 
              "pr <- plumber::plumb('/app/plumber.R'); pr$run(host='0.0.0.0', port=8080)"
            ];
            ExposedPorts = { "8080/tcp" = {}; };
            Env = [ 
              "PORT=8080"
              "R_HOME=${pkgs.rEnv}/lib/R"
            ];
            WorkingDir = "/app";
          };
        };

        # --- GCE VM Image ---
        gce-image = self.nixosConfigurations.gce-server.config.system.build.images.gce;

        default = self.packages.${system}.container;
      };

      nixosConfigurations.gce-server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                rEnv = prev.rWrapper.override {
                  packages = with prev.rPackages; [
                    plumber
                    jsonlite
                  ];
                };
              })
            ];
            
            system.stateVersion = "25.05";
            
            # Basic services
            services.openssh.enable = true;
            
            # Cloud-init for GCE metadata
            services.cloud-init.enable = true;
            
            # Install R and plumber
            environment.systemPackages = with pkgs; [ 
              rEnv
              curl
              vim
              git
            ];
            
            # Create app directory
            systemd.tmpfiles.rules = [
              "d /app 0755 root root -"
            ];
            
            # Copy plumber app
            environment.etc."plumber.R".source = ./src/plumber.R;
            
            # Systemd service for plumber API
            systemd.services.plumber-api = {
              description = "Plumber R API";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.rEnv}/bin/Rscript -e 'pr <- plumber::plumb(\"/etc/plumber.R\"); pr$run(host=\"0.0.0.0\", port=8080)'";
                Restart = "always";
                RestartSec = 10;
                Environment = "PORT=8080";
              };
            };
            
            # GCE image configuration
            image.modules.gce = {
              imports = [ 
                "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
                "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
              ];
              
              # Open firewall for plumber
              networking.firewall.allowedTCPPorts = [ 8080 ];
            };
          })
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ 
          rEnv
          opentofu
          google-cloud-sdk
          skopeo
          jq
          gh
        ];
        shellHook = "echo '❄️ Hub and Spoke Demo Environment Active'";
      };
    };
}
