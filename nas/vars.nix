{
  ip = builtins.readFile ../app/config/prod/ip;
  ip_local = "192.168.1.200";
  base_host = "nas.local";
  base_dn = "DC=nas,DC=local";
  dns_ip = "192.168.1.254";
}
