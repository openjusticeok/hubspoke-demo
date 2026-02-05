{
  description = "Hub & Spoke Demo: R + Plumber (Idiomatic rstats-on-nix + nix2container)";

  inputs = {
    # Standard NixOS for system tools
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # R-optimized nixpkgs (Latest: 2026-02-05)
    r-nixpkgs.url = "github:rstats-on-nix/nixpkgs/2026-02-05";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, r-nixpkgs, nix2container, ... }:
    let
      system = "x86_64-linux";
      
      # Standard pkgs for system tools
      pkgs = import nixpkgs { inherit system; };
      
      # R-optimized pkgs (solves all library issues automatically)
      pkgsR = import r-nixpkgs { inherit system; };
      
      n2c = nix2container.packages.${system}.nix2container;

      # IDIOMATIC R ENVIRONMENT (rWrapper handles all deps: BLAS, LAPACK, PCRE, etc.)
      rEnv = pkgsR.rWrapper.override {
        packages = with pkgsR.rPackages; [ 
          plumber 
          jsonlite 
        ];
      };

      # Application files
      appFiles = pkgs.runCommand "plumber-app" { } ''
        mkdir -p $out/app
        cp ${./src/plumber.R} $out/app/plumber.R
      '';

    in
    {
      packages.${system} = {
        # --- Container for Cloud Run (nix2container + rWrapper) ---
        container = n2c.buildImage {
          name = "hubspoke-demo";
          tag = self.shortRev or "latest";
          
          # rEnv contains R, Rscript, plumber, jsonlite, and all system libraries
          contents = [
            rEnv           # Self-contained R environment
            pkgs.bash      # Shell access
            pkgs.coreutils # Basic tools
            appFiles       # Application code
          ];

          config = {
            # rWrapper sets up R_LIBS_SITE automatically
            Cmd = [ 
              "${rEnv}/bin/Rscript"
              "-e" 
              "pr <- plumber::plumb('/app/plumber.R'); pr$run(host='0.0.0.0', port=8080)"
            ];
            ExposedPorts = { "8080/tcp" = { }; };
            WorkingDir = "/app";
          };
        };
        
        # --- GCE VM Image ---
        gce-image = self.nixosConfigurations.gce-server.config.system.build.images.gce;

        default = self.packages.${system}.container;
      };

      # --- GCE NixOS Configuration (also uses rEnv from pkgsR) ---
      nixosConfigurations.gce-server = pkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                # Use rEnv from rstats-on-nix (handles all dependencies)
                rEnv = rEnv;
              })
            ];
            
            system.stateVersion = "25.05";
            
            # Basic services
            services.openssh.enable = true;
            services.cloud-init.enable = true;
            
            # Install R and system tools
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
                ExecStart = "${rEnv}/bin/Rscript -e 'pr <- plumber::plumb(\"/etc/plumber.R\"); pr$run(host=\"0.0.0.0\", port=8080)'";
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
              networking.firewall.allowedTCPPorts = [ 8080 ];
            };
          })
        ];
      };

      # --- Development Shell ---
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
