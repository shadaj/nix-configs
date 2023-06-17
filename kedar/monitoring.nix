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

  services.grafana = {
    enable = true;
    settings.server.protocol = "socket";
  };
}
