{ config, pkgs, ... }:
{
  services.prometheus = {
    enable = true;
    exporters.smartctl = {
      user = "root";
      enable = true;
    };

    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };

    scrapeConfigs = [
      {
        job_name = "smartctl";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}" ];
        }];
      }

      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };

  # https://github.com/NixOS/nixpkgs/pull/176553
  systemd.services."prometheus-smartctl-exporter".serviceConfig.DeviceAllow = pkgs.lib.mkOverride 50 [
    "block-blkext rw"
    "block-sd rw"
    "char-nvme rw"
  ];

  services.grafana = {
    enable = true;
    settings.server.protocol = "socket";
  };
}
