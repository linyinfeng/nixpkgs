import ./make-test-python.nix ({ lib, ... }:

with lib;

{
  name = "godns";
  meta.maintainers = with maintainers; [ tboerger ];

  nodes.machine =
    { pkgs, ... }:
    {
      services.godns.instances.instance1 = {
        settings = {
          provider = "Cloudflare";
          login_token = "API Token";
          domains = [
            {
              domain_name = "example.com";
              sub_domains = [ "www" "test" ];
            }
          ];
          ip_type = "IPv4";
        };
      };
      services.godns.instances.instance2 = {
        settings = {
          provider = "Cloudflare";
          login_token = "API Token";
          domains = [
            {
              domain_name = "example.com";
              sub_domains = [ "www" "test" ];
            }
          ];
          ip_type = "IPv6";
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("godns-instance1.service")
    machine.wait_for_unit("godns-instance2.service")
  '';
})
