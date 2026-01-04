{ config, pkgs, ...}:
  let 
        vars = import ./vars.nix;
        ip = "100.110.67.40";
  in
{
    networking.firewall.allowedUDPPorts= [ 53 ];
    environment.etc."dns.db".text = '' 
      $TTL 3600
      @   IN  SOA ns1.${vars.base_host}. admin.${vars.base_host}. (
              2023101001 ; Serial
              3600       ; Refresh
              1800       ; Retry
              604800     ; Expire
              86400      ; Minimum TTL
      )
      ;
      @    IN  NS  ns1.${vars.base_host}.
      ns   IN  A ${ip} 
      *    IN  A ${ip}
    '';

    systemd.services.coredns.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "1s"; 
      StartLimitBurst = 15;
     };

    services.coredns= {
      enable = true;
      extraArgs = [
        "-dns.port=53"
      ];

      config = ''
        . {
            errors
            health
            ready
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
            log
          }
          ${vars.base_host}:53 {
            file /etc/dns.db
            log
            errors
          }
          example.org {
            whoami
          }
         '';
    };
}
