{ lib, ... }:
{
  options.result = lib.mkOption {
    type = with lib.types; listOf str;
  };
}
