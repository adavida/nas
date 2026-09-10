{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
{
  services.journald.extraConfig = "Storage=persistent";

  environment.etc."grafana-secret" = {
    text = "SW2YcwTIb9zpOOhoPsMm";
    mode = "0440";
    group = "grafana";
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      compactor = {
        retention_enabled = true;
        working_directory = "/var/lib/loki/compactor";
        delete_request_store = "filesystem";
      };
      limits_config = {
        allow_structured_metadata = true;
        retention_period = "720h";
      };
      analytics.reporting_enabled = false;
    };
  };

  systemd.services.vector.serviceConfig.SupplementaryGroups = [
    "nginx"
    "jellyfin"
    "nextcloud"
  ];
  systemd.services.vector.serviceConfig.ReadOnlyPaths = [ "/var/log/journal" ];
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sources = {
        journal.type = "journald";
        nginx_access = {
          type = "file";
          include = [ "/var/log/nginx/access.log" ];
        };
        nginx_error = {
          type = "file";
          include = [ "/var/log/nginx/error.log" ];
        };
        jellyfin = {
          type = "file";
          include = [ "/var/log/jellyfin/*.log" ];
        };
        nextcloud = {
          type = "file";
          include = [ "/data/ssd/nc/data/nextcloud.log" ];
        };
      };
      sinks.loki_journal = {
        type = "loki";
        inputs = [ "journal" ];
        endpoint = "http://127.0.0.1:3100";
        encoding.codec = "json";
        labels = {
          host = "{{ host }}";
          unit = "{{ _SYSTEMD_UNIT }}";
        };
      };
      sinks.loki_nginx = {
        type = "loki";
        inputs = [
          "nginx_access"
          "nginx_error"
          "jellyfin"
          "nextcloud"
        ];
        endpoint = "http://127.0.0.1:3100";
        encoding.codec = "json";
        labels = {
          host = "{{ host }}";
          file = "{{ file }}";
        };
      };
    };
  };
  
  users.users.grafana.extraGroups = [ "authelia-main" ];

  services.grafana = {
    enable = true;
    provision = {
      dashboards.settings.providers = [
        {
          name = "nas";
          options.path = "/etc/nixos/grafana-dashboards";
          type = "file";
        }
      ];
      datasources.settings.datasources = [
        {
          access = "proxy";
          isDefault = true;
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:3100";
        }
        {
          access = "proxy";
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
        }
      ];
    };
    settings = {
      auth.disable_login_form = true; # force Authelia seul, plus de admin/admin local (break-glass via allow_sign_up false déjà)
      "auth.generic_oauth" = {
        allowed_groups = "admin";
        api_url = "https://authelia.${vars.base_host}/api/oidc/userinfo";
        auth_url = "https://authelia.${vars.base_host}/api/oidc/authorization";
        auto_login = true; # force Authelia : redirige /login vers Authelia sans passer par formulaire Grafana
        client_id = "grafana";
        client_secret = "$__file{/etc/nixos/secrets/authelia/oicd_grafana_secret}";
        email_attribute_path = "email";
        enabled = true;
        groups_attribute_path = "groups";
        login_attribute_path = "preferred_username";
        name = "Authelia";
        name_attribute_path = "preferred_username";
        role_attribute_path = "grafana_role";
        scopes = "openid profile email groups grafana_scope";
        token_url = "https://authelia.${vars.base_host}/api/oidc/token";
        tls_skip_verify_insecure = true; # ponytail: wildcard sans SAN (secrets/makefile:35) → x509 legacy CN, skip jusqu'à rotation SAN
        use_pkce = true;
      };
      security.secret_key = "$__file{/etc/grafana-secret}";
      server = {
        domain = "log.${vars.base_host}";
        http_addr = "127.0.0.1";
        http_port = 3001;
        root_url = "https://log.${vars.base_host}/";
      };
      users.allow_sign_up = false;
    };
  };

  services.nginx.virtualHosts."log.${vars.base_host}" = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
    };
  };
}
