{
  config,
  ...
}:
{
  boot.kernelModules = [
    "coretemp"
    "nct6775"
  ];

  services.smartd.enable = true;

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "15s";
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";
    scrapeConfigs = [
      {
        job_name = "immich-api";
        static_configs = [
          {
            targets = [ "127.0.0.1:8081" ];
          }
        ];
      }
      {
        job_name = "immich-microservices";
        static_configs = [
          {
            targets = [ "127.0.0.1:8082" ];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "hwmon"
      "systemd"
      "thermal_zone"
    ];
    listenAddress = "127.0.0.1";
    port = 9100;
  };
}
