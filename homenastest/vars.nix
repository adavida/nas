{
  base_dn = "dc=nas-test,dc=local";
  base_host = "nas-test.local";
  ca = (builtins.readFile ./homeCA.crt);
  dns_ip = "192.168.1.254";
  ip = "100.65.188.54";
  photoprism_originals_path = "/data/ssd/photoprism-originals";
}
