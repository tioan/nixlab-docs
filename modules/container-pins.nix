# Registry images for virtualisation.oci-containers, pinned by digest.
#
# A tag - `latest` as much as `1.3.1` - is whatever the registry says it is
# today; a digest is the content itself, the way a fetcher's hash is. Each pin
# names the image, the tag its digest was read from (for people and for the
# version check), the digest that is pulled, and the upstream repository the
# version check looks for releases in. A container uses the pin's `ref`:
#
#   services.containerPins.images.app = {
#     image = "ghcr.io/example/app";
#     tag = "1.2.3";
#     digest = "sha256:0123...";
#     source = "https://github.com/example/app";
#   };
#   virtualisation.oci-containers.containers.app.image =
#     config.services.containerPins.images.app.ref;
#
# With `enforce` (the default), every oci container on the host has to be
# pinned by digest or built locally (pull = "never"), and none may carry
# podman's auto-update label: `podman auto-update` would otherwise move the
# image behind the configuration's back.
{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.services.containerPins;

  pin = types.submodule (
    { config, ... }:
    {
      options = {
        image = mkOption {
          type = types.str;
          example = "ghcr.io/example/app";
          description = "Image name without tag or digest.";
        };
        tag = mkOption {
          type = types.str;
          example = "1.2.3";
          description = "Tag the digest was read from. Informational only: what is pulled is the digest.";
        };
        digest = mkOption {
          type = types.strMatching "sha256:[0-9a-f]{64}";
          description = "Digest of the image (for a multi-arch image: of its index).";
        };
        source = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://github.com/example/app";
          description = "Upstream repository, where new releases are looked up.";
        };
        ref = mkOption {
          type = types.str;
          readOnly = true;
          default = "${config.image}@${config.digest}";
          defaultText = lib.literalExpression ''"''${image}@''${digest}"'';
          description = "What a container's `image` is set to.";
        };
      };
    }
  );

  containers = config.virtualisation.oci-containers.containers;
  pinned = c: lib.hasInfix "@sha256:" c.image || (c.pull or null) == "never";
  autoUpdate =
    c:
    lib.any (lib.hasInfix "io.containers.autoupdate") (
      c.extraOptions ++ lib.attrNames (c.labels or { })
    );
in
{
  options.services.containerPins = {
    images = mkOption {
      type = types.attrsOf pin;
      default = { };
      description = "Pinned registry images, by container name.";
    };
    enforce = mkOption {
      type = types.bool;
      default = true;
      description = "Fail evaluation for an oci container that is not pinned by digest, or that carries podman's auto-update label.";
    };
  };

  config.assertions = lib.mkIf cfg.enforce (
    lib.concatLists (
      lib.mapAttrsToList (name: c: [
        {
          assertion = pinned c;
          message = "oci container ${name}: image ${c.image} is not pinned by digest (services.containerPins, modules/container-pins.nix)";
        }
        {
          assertion = !(autoUpdate c);
          message = "oci container ${name}: carries io.containers.autoupdate; images change by a pin bump only (modules/container-pins.nix)";
        }
      ]) containers
    )
  );
}
