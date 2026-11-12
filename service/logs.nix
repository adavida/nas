{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
let
  grafanaClientId = "grafana";
  logHost = "log.${vars.base_host}";
  logUrl = "https://${logHost}";
  lokiEndpoint = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
  portailUrl = config.services.portail.appUrl;
in
{
  services.journald.extraConfig = "Storage=persistent";

  environment.etc."grafana-secret" = {
    group = "grafana";
    mode = "0440";
    text = "SW2YcwTIb9zpOOhoPsMm";
  };

  services.loki = {
    enable = true;
    configuration = {
      analytics.reporting_enabled = false;
      auth_enabled = false;
      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
      };
      compactor = {
        delete_request_store = "filesystem";
        retention_enabled = true;
        working_directory = "/var/lib/loki/compactor";
      };
      limits_config = {
        allow_structured_metadata = true;
        retention_period = "720h";
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          index = {
            prefix = "index_";
            period = "24h";
          };
          object_store = "filesystem";
          schema = "v13";
          store = "tsdb";
        }
      ];
      server.http_listen_port = 3100;
    };
  };

  systemd.services.vector.serviceConfig = {
    ReadOnlyPaths = [ "/var/log/journal" ];
    SupplementaryGroups = [
      "nginx"
      "jellyfin"
      "nextcloud"
    ];
  };
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sinks = {
        loki_journal = {
          endpoint = lokiEndpoint;
          encoding.codec = "json";
          inputs = [ "journal" ];
          labels = {
            host = "{{ host }}";
            unit = "{{ _SYSTEMD_UNIT }}";
          };
          type = "loki";
        };
        loki_nginx = {
          endpoint = lokiEndpoint;
          encoding.codec = "json";
          inputs = [
            "nginx_access"
            "nginx_error"
            "jellyfin"
            "nextcloud"
          ];
          labels = {
            file = "{{ file }}";
            host = "{{ host }}";
          };
          type = "loki";
        };
      };
      sources = {
        jellyfin = {
          include = [ "/var/log/jellyfin/*.log" ];
          type = "file";
        };
        journal.type = "journald";
        nextcloud = {
          include = [ "${config.services.nextcloud.datadir}/data/nextcloud.log" ];
          type = "file";
        };
        nginx_access = {
          include = [ "/var/log/nginx/access.log" ];
          type = "file";
        };
        nginx_error = {
          include = [ "/var/log/nginx/error.log" ];
          type = "file";
        };
      };
    };
  };

  services.grafana = {
    enable = true;
    provision = {
      dashboards.settings.providers = [
        {
          name = "nas";
          options.path = "/etc/nixos/grafana-dashboards";
          options.updateIntervalSeconds = 30;
          type = "file";
        }
      ];
      datasources.settings.datasources = [
        {
          access = "proxy";
          isDefault = true;
          name = "Loki";
          type = "loki";
          url = lokiEndpoint;
        }
        {
          access = "proxy";
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
      ];
    };
    settings = {
      auth.disable_login_form = true; # force Portail only, no local admin/admin
      "auth.generic_oauth" = {
        allowed_groups = "admin";
        api_url = "${portailUrl}/api/oidc/userinfo";
        auth_url = "${portailUrl}/api/oidc/authorization";
        auto_login = true; # redirect /login to Portail without going through the Grafana form
        client_id = grafanaClientId;
        client_secret = "$__file{${config.services.portail.oidc.secretsDir}/grafana_secret}";
        email_attribute_path = "email";
        enabled = true;
        groups_attribute_path = "groups";
        login_attribute_path = "preferred_username";
        name = "Portail";
        name_attribute_path = "preferred_username";
        role_attribute_path = "contains(groups, 'admin') && 'Admin' || 'Viewer'";
        scopes = "openid profile email groups";
        signout_redirect_url = "${portailUrl}/logout?rd=${logUrl}/";
        token_url = "${portailUrl}/api/oidc/token";
        tls_skip_verify_insecure = true; # ponytail: wildcard without SAN (secrets/makefile:35) → x509 legacy CN, skip until SAN rotation
        use_pkce = true;
      };
      security.secret_key = "$__file{/etc/grafana-secret}";
      server = {
        domain = logHost;
        http_addr = "127.0.0.1";
        http_port = 3001;
        root_url = "${logUrl}/";
      };
      users.allow_sign_up = false;
    };
  };

  services.nginx.virtualHosts.${logHost} = {
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
  };
  systemd.services.grafana = {
    after = [ "portail-backend.service" ];
    requires = [ "portail-backend.service" ];
    restartIfChanged = true;
  };
  services.portail.apps = [
    {
      description = "Dashboards et alerting";
      icon = "https://grafana.com/assets/img/fav32.png";
      name = "Grafana";
      oidc = {
        clientId = grafanaClientId;
        enable = true;
        group = "grafana";
        redirectUris = [ "${logUrl}/login/generic_oauth" ];
        user = "grafana";
      };
      url = "${logUrl}/";
    }
  ];
}
