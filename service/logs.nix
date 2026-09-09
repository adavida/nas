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
    settings = {
      server = {
        http_port = 3001;
        http_addr = "127.0.0.1";
        domain = "log.${vars.base_host}";
        root_url = "https://log.${vars.base_host}/";
      };
      security.secret_key = "$__file{/etc/grafana-secret}";
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        allow_sign_up = true;
        auto_login = true; # force Authelia : redirige /login vers Authelia sans passer par formulaire Grafana
        scopes = "openid profile email groups grafana_scope";
        auth_url = "https://authelia.${vars.base_host}/api/oidc/authorization";
        token_url = "https://authelia.${vars.base_host}/api/oidc/token";
        api_url = "https://authelia.${vars.base_host}/api/oidc/userinfo";
        client_id = "grafana";
        client_secret = "$__file{/etc/nixos/secrets/authelia/oicd_grafana_secret}";
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        name_attribute_path = "preferred_username";
        email_attribute_path = "email";
        role_attribute_path = "grafana_role";
        allowed_groups = "admin";
        use_pkce = true;
        tls_skip_verify_insecure = true; # ponytail: wildcard sans SAN (secrets/makefile:35) → x509 legacy CN, skip jusqu'à rotation SAN
      };
      auth.disable_login_form = true; # force Authelia seul, plus de admin/admin local (break-glass via allow_sign_up false déjà)
      users.allow_sign_up = false;
    };
    provision.datasources.settings.datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:3100";
        isDefault = true;
      }
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:9090";
      }
    ];
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
