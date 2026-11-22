# Reusable module: how long a newer tag of a tag-pinned flake input has been
# waiting (admin/nixlab#327, decision 4a). Inputs pinned by tag are bumped by
# hand (`just bump`), so nothing else notices a new release of them.
#
# The pins come from the flake.lock this system was built from (lockFile):
# every direct input of type github whose owner is in `owners` and whose ref
# is a version tag (v1.2.3 / 1.2.3). A writer of modules/textfile-metrics.nix
# asks the GitHub API for each one's newest version tag, a few unauthenticated
# requests per input and run, and exports
#
#   <prefix>flake_input_newer_tag_age_seconds{input,repo,pinned,latest}
#
# 0 while the pin is the newest tag, else the newest tag's age. The script
# is modules/flake-input-tags.sh.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.flakeInputTags;
  lock = builtins.fromJSON (builtins.readFile cfg.lockFile);
  original = key: lock.nodes.${key}.original or { };
  pinnedByTag =
    key:
    let
      o = original key;
    in
    builtins.isString key
    && (o.type or null) == "github"
    && lib.elem (o.owner or null) cfg.owners
    && builtins.match "v?[0-9]+([.][0-9]+)+" (o.ref or "") != null;
  watched = lib.filterAttrs (_: pinnedByTag) lock.nodes.${lock.root}.inputs;
  inputsFile = pkgs.writeText "flake-input-tags" (
    lib.concatStrings (
      lib.mapAttrsToList (
        name: key:
        let
          o = original key;
        in
        "${name} ${o.owner}/${o.repo} ${o.ref}\n"
      ) watched
    )
  );
in
{
  imports = [ ./textfile-metrics-lab.nix ];

  options.services.flakeInputTags = {
    enable = lib.mkEnableOption "the age of newer tags of tag-pinned flake inputs as metrics";

    lockFile = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./flake.lock";
      description = "flake.lock of the flake this system is built from.";
    };

    owners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "my-github-account" ];
      description = "GitHub owners whose tag-pinned inputs are watched.";
    };

    inputs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = lib.mapAttrs (_: key: (original key).ref) watched;
      description = "The watched inputs and their pinned tags, as read from lockFile.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (n: builtins.match "[A-Za-z0-9_-]+" n != null) (lib.attrNames watched);
        message = "services.flakeInputTags: input names must be [A-Za-z0-9_-]+ (they become metric labels).";
      }
    ];

    services.textfileMetrics.writers.flake-input-tags = {
      description = "Age of newer tags of tag-pinned flake inputs";
      script = builtins.readFile ./flake-input-tags.sh;
      path = [
        pkgs.curl
        pkgs.jq
        pkgs.gnugrep
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
          INPUTS = "${inputsFile}";
          PREFIX = config.services.textfileMetrics.metricPrefix;
        };
      };
    };
  };
}
