{
  base_dn = "DC=nas,DC=local";
  base_host = "nas.local";
  ca = (builtins.readFile ../secrets/certs/homeCA.crt);
  dns_ip = "192.168.1.254";
  ip = "100.110.67.40";
  ip_local = "192.168.1.200";
  photoprism_originals_path = "/data/main/photo";
}
