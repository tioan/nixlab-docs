# Reusable module: how long a newer upstream release of a pinned package has
# been waiting. Packages taken from a nixpkgs pin that is bumped by hand
# (flake.nix: nixpkgs-readeck and its siblings) do not move with the nightly
# update, and nothing else notices when upstream has moved on - the weekly
# version check (pkgs/version-check) only reports it. Sibling of
# modules/flake-input-tags.nix, which does the same for flake inputs pinned by
# tag.
#
#   services.pinnedReleases.packages.readeck = {
#     version = config.services.readeck.package.version;
#     api = "https://codeberg.org/api/v1";   # Forgejo; GitHub by default
#     repo = "readeck/readeck";
#   };
#
# The version comes from the evaluated package, so it follows the pin by
# itself. A writer of modules/textfile-metrics-lab.nix asks the forge's releases
# API (GitHub and Forgejo/Gitea answer alike, unauthenticated, one request
# per package and run) and exports
#
#   <prefix>pinned_newer_release_age_seconds{package,repo,pinned,latest}
#
# 0 while the pin is the newest stable release, else the age of the oldest
# release newer than the pin. The script is modules/pinned-releases.sh.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pinnedReleases;
  packagesFile = pkgs.writeText "pinned-releases" (
    lib.concatStrings (
      lib.mapAttrsToList (name: p: "${name} ${p.api} ${p.repo} ${p.version}\n") cfg.packages
    )
  );
in
{
  imports = [ ./textfile-metrics-lab.nix ];

  options.services.pinnedReleases.packages = lib.mkOption {
    default = { };
    description = "Pinned packages whose newer upstream releases are watched, by name.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          version = lib.mkOption {
            type = lib.types.str;
            example = lib.literalExpression "config.services.readeck.package.version";
            description = "The running version, usually read from the package.";
          };
          api = lib.mkOption {
            type = lib.types.str;
            default = "https://api.github.com";
            example = "https://codeberg.org/api/v1";
            description = "API base of the forge: GitHub's, or a Forgejo/Gitea instance's /api/v1.";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            example = "readeck/readeck";
            description = "owner/name of the upstream repository on that forge.";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg.packages != { }) {
    assertions = [
      {
        assertion = lib.all (n: builtins.match "[A-Za-z0-9_-]+" n != null) (lib.attrNames cfg.packages);
        message = "services.pinnedReleases: package names must be [A-Za-z0-9_-]+ (they become metric labels).";
      }
      {
        assertion = lib.all (
          p:
          builtins.match "[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+" p.repo != null
          && builtins.match "[^ ]+" p.api != null
          && builtins.match "[^ ]+" p.version != null
        ) (lib.attrValues cfg.packages);
        message = "services.pinnedReleases: repo must be owner/name, api and version without spaces.";
      }
    ];

    services.textfileMetrics.writers.pinned-releases = {
      description = "Age of newer upstream releases of pinned packages";
      script = builtins.readFile ./pinned-releases.sh;
      path = [
        pkgs.curl
        pkgs.jq
        pkgs.gnugrep
        pkgs.gnused
      ];
      hardening.network = "any";
      timer = {
        OnBootSec = "10min";
        OnUnitActiveSec = "6h";
      };
      unit = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          PACKAGES = "${packagesFile}";
          PREFIX = config.services.textfileMetrics.metricPrefix;
        };
      };
    };
  };
}
