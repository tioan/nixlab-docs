# The private docs site (flake package docs-site, built from docs/) on the
# NetBird mesh under doku.homelab.example.
#
# Who may read it is the allow list (option allow): the whole mesh by
# default, in this lab only the admins' devices - the docs carry every
# internal address and how the lab is run, which is more than everyone with
# a device in the mesh needs to see. Enforced here in nginx because the
# NetBird policies cannot tell this site apart from the other services on
# the same hosts (terraform/netbird/admin-peers.tf has the reasoning).
#
# Mesh-only like the other admin names: the name is a NetBird DNS zone with
# one A record per host that imports this module
# (terraform/netbird/mesh-services.tf), public DNS has no record, and the
# vhost admits only mesh addresses. Certificate via DNS-01 (modules/acme.nix)
# - each host gets its own; hosts whose deSEC token is limited to named
# records need "doku" in their acme_names (terraform/desec-tokens/main.tf).
#
# Two more ways in, both optional and both only additions - the mesh way
# above stays the one that does not depend on anything but the host
# (decided 2026-10-23):
#  - Login from the internet (option login): a NetBird reverse proxy
#    service with SSO (terraform/netbird/reverse-proxy.tf, doku_login)
#    forwards to a listener of its own here. The proxy sends a secret
#    header, and only requests that carry it get the docs - every person's
#    devices reach this port over the mesh (to-servers), and without the
#    header the admin-only rule would end at the port. doku.homelab.example/login
#    leads there; without zummi (Pocket ID) and grammi (proxy) it is gone,
#    which is fine for a way meant for a device without NetBird.
#  - The home LAN (option lan): the router answers doku.homelab.example with
#    this host's LAN address, and every LAN device gets the docs except the
#    ones on a deliberate deny list. A deny list by address only catches
#    devices with a fixed one; guests and anything with a changing address
#    are in.
#
# On more than one host on purpose: the docs are what you read when
# something is broken, so they must not depend on a single machine - least
# of all on grammi, which runs the NetBird server and the reverse proxy.
# Every host builds the site itself from its /etc/nixos checkout, so all of
# them serve the same commit after a deploy or the nightly upgrade.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.docsSite;

  # The page a device outside the allow list gets instead of nginx's bare
  # "403 Forbidden": what this is, why it is closed, and how a device gets
  # in. Plain HTML, nothing loaded from elsewhere; the font is the site's
  # own (assets/fonts/, see docs/assets.nix), with system fonts as the
  # fallback. Deliberately not a page built by Zensical: its pages carry
  # the whole navigation, and a closed door should not list every page
  # title behind it. Server-side include for the one dynamic bit, the
  # address the request came from - which device it was is the first
  # question when a device that should get in does not.
  errorPages = pkgs.writeTextDir "403.html" ''
    <!doctype html>
    <html lang="de">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>Kein Zugriff – nixlab</title>
    <style>
      @font-face { font-family: "Inter"; font-style: normal; font-weight: 100 900; font-display: swap; src: url("/assets/fonts/Inter.woff2") format("woff2"); }
      @font-face { font-family: "JetBrains Mono"; font-style: normal; font-weight: 100 800; font-display: swap; src: url("/assets/fonts/JetBrainsMono.woff2") format("woff2"); }
      :root { --bg: #ffffff; --fg: #1f2329; --muted: #5f6670; --line: #e3e6ea; --code: #f3f4f6; --accent: #4051b5; }
      @media (prefers-color-scheme: dark) { :root { --bg: #1e2129; --fg: #e3e6ea; --muted: #a0a7b2; --line: #343a46; --code: #2a2f3a; --accent: #8c9eff; } }
      * { box-sizing: border-box; }
      body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 1.5rem 1rem; background: var(--bg); color: var(--fg); font: 16px/1.6 "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
      main { width: 100%; max-width: 38rem; }
      .brand { font-weight: 700; letter-spacing: .01em; color: var(--muted); margin: 0 0 2rem; }
      .code { font-size: 4rem; font-weight: 800; line-height: 1; margin: 0; color: var(--accent); }
      h1 { font-size: 1.6rem; margin: .5rem 0 1rem; }
      h2 { font-size: 1rem; margin: 2rem 0 .25rem; color: var(--muted); font-weight: 600; }
      p { margin: .5rem 0; }
      code { font-family: "JetBrains Mono", ui-monospace, Menlo, monospace; font-size: .9em; background: var(--code); padding: .1em .35em; border-radius: 4px; }
      section + section { border-top: 1px solid var(--line); margin-top: 2rem; padding-top: 1.5rem; }
      .addr { color: var(--muted); font-size: .9rem; }
    </style>
    </head>
    <body>
    <main>
      <p class="brand">nixlab</p>
      <p class="code">403</p>
      <section lang="de">
        <h1>Kein Zugriff auf die Dokumentation</h1>
        <p>Die private nixlab-Dokumentation ist nur von Admin-Geräten im Mesh, aus dem Heimnetz und nach Login unter <code>/login</code> lesbar. Dieses Gerät gehört nicht dazu.</p>
        <h2>Gerät freischalten</h2>
        <p>Das Gerät in die NetBird-Gruppe <code>admin-workstations</code> aufnehmen (<code>terraform/netbird/subraum.tf</code>), dann <code>just netbird-apply</code> und aldrin und ursalia deployen.</p>
      </section>
      <section lang="en">
        <h1>No access to the documentation</h1>
        <p>The private nixlab documentation can only be read from admin devices in the mesh, from the home LAN and after logging in at <code>/login</code>. This device is not one of them.</p>
        <h2>Letting a device in</h2>
        <p>Add the device to the NetBird group <code>admin-workstations</code> (<code>terraform/netbird/subraum.tf</code>), then run <code>just netbird-apply</code> and deploy aldrin and ursalia.</p>
      </section>
      <p class="addr">Anfrage von / request from <code><!--# echo var="remote_addr" --></code></p>
    </main>
    </body>
    </html>
  '';
in
{
  options.services.docsSite = {
    enable = lib.mkEnableOption "the private docs site on the mesh";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The built site - the flake's docs-site package.";
    };

    fqdn = lib.mkOption {
      type = lib.types.str;
      default = "doku.homelab.example";
      description = "Name the site is served under (a mesh-only NetBird DNS zone).";
    };

    allow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.0.2.0/24" ];
      description = ''
        Addresses or networks nginx serves the site to; everyone else gets
        403, with a page that says why and how a device gets in. Default:
        the whole mesh. The lab sets the admins' devices from
        terraform/netbird/admin-peers.json (flake.nix) - see the header of
        terraform/netbird/admin-peers.tf for why it is an address list.
      '';
    };

    redirectPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      example = 8091;
      description = ''
        Port of a plain-HTTP listener that answers every request with a
        redirect to redirectTo, keeping the path - the target of the NetBird
        reverse proxy service for the same name, so a visitor from outside
        the mesh lands on the public docs. A port of its own because the
        proxy's peer has no address that is known in advance; the port is
        only open on the mesh (nb-mesh is a trusted interface) and admits
        only the mesh. null: no listener.
      '';
    };

    login = {
      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        example = 8094;
        description = ''
          Port of a plain-HTTP listener that serves the docs to the NetBird
          reverse proxy's login service (SSO) - only to requests carrying the
          header X-Nixlab-Docs-Key with the value of the sops secret
          login.secret, which the proxy adds. Mesh only, like redirectPort.
          null: no listener.
        '';
      };

      fqdn = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "docs-login.example.org";
        description = ''
          Public name of the login service. /login on this site and on the
          redirect listener leads there; empty: /login leads to the start
          page.
        '';
      };

      secret = lib.mkOption {
        type = lib.types.str;
        default = "docs_login_key";
        description = "sops secret (in the host's default sops file) with the header value the proxy sends.";
      };
    };

    lan = {
      networks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "192.0.2.0/24" ];
        description = ''
          LAN networks that get the docs on top of the allow list - for a
          router that answers the site's name with this host's LAN address.
        '';
      };

      deny = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Addresses inside lan.networks that get the 403 page instead.";
      };

      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "eth0" ];
        description = "Interfaces on which the firewall opens 443 for lan.networks.";
      };
    };

    redirectTo = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "https://example.github.io/docs";
      description = "Where redirectPort sends visitors, without a trailing slash; the request path is appended.";
    };
  };

  config = lib.mkIf cfg.enable {
    # An empty list would only leave "deny all" - nobody could read the
    # docs, and nothing else would say why.
    assertions = [
      {
        assertion = cfg.allow != [ ];
        message = "services.docsSite.allow is empty - nobody could read the docs site";
      }
      {
        assertion = cfg.redirectPort == null || cfg.redirectTo != "";
        message = "services.docsSite.redirectPort is set but redirectTo is empty";
      }
      {
        assertion = cfg.login.port == null || cfg.login.fqdn != "";
        message = "services.docsSite.login.port is set but login.fqdn is empty";
      }
    ];

    networking.firewall.interfaces = lib.genAttrs cfg.lan.interfaces (_: {
      allowedTCPPorts = [ 443 ];
    });

    # The login listener's key stays out of the world-readable store: a map
    # rendered by sops-nix at activation, included at runtime (as in
    # modules/maintenance.nix).
    sops.secrets.${cfg.login.secret} = lib.mkIf (cfg.login.port != null) { };
    sops.templates."nginx-docs-login.conf" = lib.mkIf (cfg.login.port != null) {
      owner = "nginx";
      content = ''
        map $http_x_nixlab_docs_key $nixlab_docs_key_ok {
          default "";
          "${config.sops.placeholder.${cfg.login.secret}}" 1;
        }
      '';
      reloadUnits = [ "nginx.service" ];
    };

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      appendHttpConfig = lib.mkIf (cfg.login.port != null)
        "include ${config.sops.templates."nginx-docs-login.conf".path};";
      # Wildcard instead of the host's defaults: the mesh address is
      # NetBird's to assign and nb-mesh may come up after nginx, and a host
      # may bind its public vhosts to its public addresses only (aldrin).
      # The allow list (option allow) is what keeps it mesh-only, or
      # admins-only. [::] already, for when the mesh gets IPv6 (then the v6
      # addresses go into the allow list as well).
      virtualHosts.${cfg.fqdn} = {
        listenAddresses = [ "0.0.0.0" "[::]" ];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        root = cfg.package;
        # The allow list guards the site itself, not the whole server: the
        # 403 page and the font it uses must stay reachable for exactly the
        # devices that are turned away - with the list on the server block,
        # nginx would deny its own error page and fall back to its bare one.
        extraConfig = "error_page 403 /_errors/403.html;\n";
        # Deny list first: nginx takes the first rule that matches.
        locations."/".extraConfig =
          lib.concatMapStrings (a: "deny ${a};\n") cfg.lan.deny
          + lib.concatMapStrings (a: "allow ${a};\n") (cfg.allow ++ cfg.lan.networks)
          + "deny all;\n";
        # doku.homelab.example/login is the way in from the internet; here, where
        # the docs answer anyway, it just leads to the start page.
        locations."~ ^/login/?$".return = "302 /";
        # Only reachable as the target of error_page (internal), so it is
        # not a page of its own; ssi fills in the client address.
        locations."^~ /_errors/" = {
          alias = "${errorPages}/";
          extraConfig = ''
            internal;
            ssi on;
          '';
        };
        # The 403 page's font. Two open source font files, nothing about
        # the lab - open to anyone who reaches the vhost at all.
        locations."^~ /assets/fonts/".extraConfig = "";
      };

      # Redirect listener for the reverse proxy (option redirectPort): one
      # answer for everything, no TLS (the proxy terminates it and reaches
      # this through its tunnel), mesh only. Its own virtual host with the
      # same server name, told apart by the port.
      virtualHosts."${cfg.fqdn}-redirect" = lib.mkIf (cfg.redirectPort != null) {
        serverName = cfg.fqdn;
        listen = [
          { addr = "0.0.0.0"; port = cfg.redirectPort; }
          { addr = "[::]"; port = cfg.redirectPort; }
        ];
        # The redirect sits behind try_files on purpose: a plain "return"
        # runs in nginx's rewrite phase, before allow/deny are checked, so
        # the mesh restriction would never apply. try_files runs after the
        # access check and hands over to the named location.
        locations = {
          "/".extraConfig = ''
            allow 192.0.2.0/24;
            deny all;
            try_files /.redirect-only @redirect;
          '';
          "@redirect".return = "301 ${cfg.redirectTo}$request_uri";
        } // lib.optionalAttrs (cfg.login.fqdn != "") {
          # /login: to the login service instead of the public docs.
          "~ ^/login/?$".extraConfig = ''
            allow 192.0.2.0/24;
            deny all;
            try_files /.redirect-only @login;
          '';
          "@login".return = "302 https://${cfg.login.fqdn}/";
        };
      };

      # Login listener for the reverse proxy's SSO service (option login):
      # the docs themselves, for requests with the proxy's key only. The
      # key check is a return in the rewrite phase, the mesh check allow/
      # deny after it - both have to pass. No TLS (the proxy terminates it).
      virtualHosts."${cfg.fqdn}-login" = lib.mkIf (cfg.login.port != null) {
        serverName = cfg.login.fqdn;
        listen = [
          { addr = "0.0.0.0"; port = cfg.login.port; }
          { addr = "[::]"; port = cfg.login.port; }
        ];
        root = cfg.package;
        extraConfig = ''
          allow 192.0.2.0/24;
          deny all;
          if ($nixlab_docs_key_ok = "") { return 403; }
          # Relative redirects: absolute ones would say http://...:port,
          # this listener's side of the proxy.
          absolute_redirect off;
        '';
        locations."~ ^/login/?$".return = "302 /";
      };
    };
  };
}
