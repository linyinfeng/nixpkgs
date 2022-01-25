{ lib, ... }:
{
  # will remove "default1"
  # will not remove "before1" and "after1", since there priority is not defaultOrderPriority
  config.result = lib.mkRemove lib.modules.defaultOrderPriority [ "before1" "default1" "after1" ];
}
