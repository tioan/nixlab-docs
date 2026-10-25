# NetBird client, joining the homelab mesh (control plane: mesh.homelab.example,
# hosts/grammi/netbird.nix; account: terraform/netbird). Runs next to
# Tailscale, not instead of it - see modules/tailscale.nix, which stays as
# it is until individual services move over.
#
# The host registers once with a single-use setup key from
# hosts/<host>/netbird.yaml, written by `just netbird-key <host>` (24 h
# valid). After that its identity lives in /var/lib/netbird-mesh/ and the
# key is spent; a host only needs a new one after losing that state.
#
# The peer shows up as <hostname>.peer.homelab.example with an address out of
# 192.0.2.0/24, in the group its setup key assigns (terraform/netbird,
# local.hosts): "servers" for the lab's own hosts, "subraum-devices" for
# cuckoosegg, which only gets what terraform/netbird/subraum.tf grants.
{ config, lib, pkgs, nixpkgs-netbird, ... }:
let
  nb = import nixpkgs-netbird { inherit (pkgs.stdenv.hostPlatform) system; };

  # services.netbird.clients.mesh -> service netbird-mesh, CLI wrapper
  # `netbird-mesh`, interface nb-mesh, hardened user/group netbird-mesh.
  client = config.services.netbird.clients.mesh;

  # The client's own Prometheus endpoint (netbird 0.80+, off by default):
  # management/signal connected, peers connected P2P vs relayed, latency per
  # direct peer, sync/login durations. 9191 is upstream's default.
  metricsPort = 9191;

  # Written by `just netbird-key <host>`. Optional on purpose: a host that
  # imports this module before its key is committed still evaluates (and
  # its nightly autoUpgrade still builds) - the client just stays logged
  # out, with a warning, instead of the whole configuration failing.
  setupKeyFile = ../hosts/${config.networking.hostName}/netbird.yaml;
  hasSetupKey = builtins.pathExists setupKeyFile;
in
{
  # Client from the same pin as the server (0.80 there, 26.05 ships 0.71):
  # one version across the mesh, bumped together with
  # `nix flake update nixpkgs-netbird`.
  services.netbird.package = nb.netbird;

  services.netbird.clients.mesh = {
    # Root, like tailscaled - not the module's default "hardened" user.
    # Hardened, the client could neither serve peer.homelab.example names (no
    # CAP_NET_BIND_SERVICE for :53 - "bind: permission denied") nor hand them
    # to systemd-resolved: the module's answer to that is a polkit rule, and
    # polkit is off on these hosts, so every SetLinkDNS call came back
    # "Permission denied" (both seen on grammi's first start). Turning on
    # polkit lab-wide for this, or a pile of extra capabilities, buys less
    # than it costs; the daemon holds CAP_NET_ADMIN either way.
    hardened = false;

    # WireGuard. openFirewall (module default) opens it on the public
    # interfaces - same reasoning as Tailscale's 41641 in modules/firewall.nix:
    # NAT traversal works without it, an open port makes direct connections
    # reliable when the other side sits behind a strict NAT.
    port = 51820;

    login = {
      enable = hasSetupKey;
      # Picked up through LoadCredential by netbird-mesh-login.service, which
      # runs `netbird up` only while the client still reports NeedsLogin -
      # so a spent or expired key in sops is harmless once registered.
      setupKeyFile = lib.mkIf hasSetupKey config.sops.secrets."netbird_setup_key".path;
    };
  };

  warnings = lib.optional (!hasSetupKey)
    "netbird: no hosts/${config.networking.hostName}/netbird.yaml - the client runs but cannot register; run `just netbird-key ${config.networking.hostName}`.";

  # The module's login script only acts on "NeedsLogin" and otherwise waits
  # for "Connected" - after one failed `netbird up` the daemon sits in
  # "LoginFailed" and the script loops forever (grammi, first deploy: the
  # login unit hung `nixos-rebuild switch` until it failed). Same script,
  # but LoginFailed counts as "try again", and it gives up after ten
  # minutes instead of never, so a deploy cannot hang on it.
  #
  # Also wanted by multi-user.target, not only by the client unit: the module
  # hangs it off netbird-mesh.service, so a key that arrives while the client
  # already runs (cuckoosegg, 2026-10-18: image first, key on the next
  # deploy) never triggers a login - switch only starts what a started or
  # restarted unit wants. With multi-user.target the switch starts the new
  # unit; on a registered host it finds "Connected" and exits at once.
  systemd.services."${client.service.name}-login" = lib.mkIf client.login.enable {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.TimeoutStartSec = "10min";
    script = lib.mkForce ''
      status() { '${lib.getExe client.wrapper}' status 2>&1 || :; }
      until status | grep --quiet ': Connected\|NeedsLogin\|LoginFailed'; do sleep 1; done
      until status | grep --quiet ': Connected'; do
        '${lib.getExe client.wrapper}' up && break
        echo "netbird up failed, retrying in 15 s" >&2
        sleep 15
      done
    '';
  };

  # NB_MANAGEMENT_URL is the env form of `netbird up --management-url`; the
  # module's wrapper (`netbird-mesh`, also used by the login service) sets it,
  # without it the client would register with NetBird's cloud.
  services.netbird.clients.mesh.environment.NB_MANAGEMENT_URL = "https://mesh.homelab.example:443";

  # Per host, next to its secrets.yaml (rule in .sops.yaml).
  sops.secrets."netbird_setup_key" = lib.mkIf hasSetupKey {
    sopsFile = setupKeyFile;
    restartUnits = [ "${client.service.name}-login.service" ];
  };

  # Same trap as tailscaled (see modules/tailscale.nix): the client registers
  # its DNS scope with systemd-resolved over D-Bus at startup, and a
  # restarted resolved forgets it - peer.homelab.example names would stop
  # resolving without anything failing.
  #
  # Second trigger: the local metrics setting below.
  systemd.services.${client.service.name}.restartTriggers =
    lib.optional config.services.resolved.enable config.environment.etc."systemd/resolved.conf".source
    ++ [ config.environment.etc."${client.dir.baseName}/config.d/50-nixos.json".text ];

  # Turned on through config.json, the only place the daemon reads it from
  # (the CLI equivalent is `netbird up --enable-local-metrics`). The module
  # merges this into /var/lib/netbird-mesh/config.json from
  # /etc/netbird-mesh/config.d/50-nixos.json in the unit's preStart - but
  # does not restart the unit when that file changes, hence the second
  # restartTrigger above, or the setting would only take effect at the next
  # reboot. Loopback only; vmagent scrapes it like every other exporter
  # (job = host, instance = "netbird"). grammi has no vmagent and scrapes it
  # in hosts/grammi/netbird.nix.
  services.netbird.clients.mesh.config = {
    LocalMetricsEnabled = true;
    LocalMetricsAddress = "127.0.0.1:${toString metricsPort}";

    # Quantum resistance: Rosenpass negotiates a post-quantum key next to
    # WireGuard's handshake and rotates it in as the tunnel's pre-shared key
    # every two minutes (against "record now, decrypt later"). Same keys as
    # `netbird up --enable-rosenpass --rosenpass-permissive`; zorlock sets
    # them in its login job, MacBook and iPhone in the app.
    #
    # Permissive since 2026-10-21 (strict from 2026-10-19): peers that both
    # run Rosenpass still use it; a peer without it can connect as well,
    # over plain WireGuard. Reason: four times in three days a tunnel to
    # the MacBook stayed "Connected (P2P)" for hours without a single
    # WireGuard handshake - the Rosenpass key expired without renewal, the
    # wg_watcher fired once, ICE reconnected at once and the watcher was
    # never re-armed (upstream netbirdio/netbird#3107, #3121). Test from
    # 2026-10-21: Rosenpass off on the MacBook only, everything else on +
    # permissive. If the dead tunnels still come back after a week,
    # Rosenpass goes off everywhere for a week (RosenpassEnabled = false
    # here and in hosts/zorlock/netbird.nix, the apps by hand).
    #
    # They came back, between two peers that both still ran it: ursalia ->
    # zorlock was dead from 2026-10-23 03:43 until a restart on 10-24, while
    # both sides reported "Connected (P2P)". At 03:38 zorlock's client
    # restarted its engine ("stopping wakeUpListen", a new Rosenpass server
    # on a new random port); at 03:42/03:43 ursalia's Rosenpass key for
    # zorlock "expired without renewal", was ratcheted, and the rendezvous
    # fallback left the two sides with different pre-shared keys. With
    # mismatched PSKs WireGuard never completes a handshake - and Rosenpass
    # itself runs inside that tunnel (see below), so it could not repair
    # it: a deadlock, ~2,700 biscuit / "session not found" errors every ten
    # minutes on ursalia. Not one pair: VictoriaLogs showed tens of
    # thousands of those errors on every host in 48 h, and "expired without
    # renewal" on each of them.
    #
    # So since 2026-10-24 Rosenpass is off everywhere, until 2026-10-31
    # (here, hosts/zorlock/netbird.nix, the apps by hand). Then decide:
    #  - no dead tunnels in that week: Rosenpass was the trigger. It stays
    #    off until upstream fixes the re-keying (#3107, #3121); look again
    #    with every NetBird bump (next: 0.81.3).
    #  - dead tunnels anyway: Rosenpass was not the cause (look at ICE and
    #    the wg_watcher instead); turn it back on, permissive.
    # Turning it back on: RosenpassEnabled = true plus
    # RosenpassPermissive = true here. The latter is left out while it is
    # off (meaningless then); the merge into config.json never removes
    # keys, so the old "true" stays there, harmlessly.
    #
    # Rosenpass listens on a random UDP port and is reached via the peer's
    # mesh address, i.e. inside the tunnel; NetBird's ACLs let that through
    # across the narrow policies too.
    RosenpassEnabled = false;
  };
  services.metricsShipping.exporterPorts.netbird = metricsPort;

  # ifstate reconciles links, routes and rules and deletes what it does not
  # know - the exact failure tailscale0 had (modules/tailscale.nix). Keep it
  # off NetBird's:
  #  - the nb-mesh interface,
  #  - its policy rules: priority 105 (lookup main, suppress_prefixlength 0)
  #    and 110 (not fwmark 0x1BD00 -> table 0x1BD0/7120), v4 and v6 - from
  #    getSetupRules() in client/internal/routemanager/systemops/
  #    systemops_linux.go,
  #  - anything routed via nb-mesh in the tables ifstate manages (NetBird puts
  #    its peer routes in its own table 7120, which ifstate does not touch, so
  #    this is a guard, not a known conflict).
  # Verified with a live 0.80 client and `ifstatecli check` against aldrin's
  # generated ifstate.yaml: with these entries nothing of NetBird's is
  # touched; without them it plans "nb-mesh del", "#105 del", "#110 del".
  # Additive to the Tailscale entries, the module system concatenates lists.
  # Inert on hosts without ifstate (ursalia).
  networking.ifstate.settings.parameters.ignore = {
    ifname = [ "^${client.interface}$" ];
    rules = [
      { priority = 105; }
      { priority = 110; }
    ];
    routes = [
      { dev = "^${client.interface}$"; }
    ];
  };

  # Trusted like tailscale0 (modules/firewall.nix), so everything a host
  # serves to the tailnet today is reachable over the mesh too - the
  # precondition for moving hosts over one by one. Who may connect is
  # decided by NetBird's policies (terraform/netbird: any peer -> servers),
  # which the client enforces in its own nftables table before this
  # firewall sees the packet; the same scope Tailscale has today with its
  # default allow-all policy. Was untrusted while nothing was served here.
  networking.firewall.trustedInterfaces = [ client.interface ];
}
