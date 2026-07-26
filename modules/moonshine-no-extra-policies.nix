upstreamModule:

{ lib, pkgs, ... }@args:

let
  rawModule =
    if builtins.isFunction upstreamModule then
      upstreamModule args
    else if builtins.typeOf upstreamModule == "path" then
      import upstreamModule args
    else
      upstreamModule;

  removePolkitExtraPolicies = value:
    if builtins.isList value then
      map removePolkitExtraPolicies value
    else if builtins.isAttrs value then
      if lib.isDerivation value then
        value
      else
        let
          mapped = builtins.mapAttrs (_: removePolkitExtraPolicies) value;
          mappedWithPatchedImports =
            if mapped ? imports && builtins.isList mapped.imports then
              mapped // {
                imports = map (imported: (import ./moonshine-no-extra-policies.nix) imported) mapped.imports;
              }
            else
              mapped;
        in
          if
            mappedWithPatchedImports ? security
            && builtins.isAttrs mappedWithPatchedImports.security
            && mappedWithPatchedImports.security ? polkit
            && builtins.isAttrs mappedWithPatchedImports.security.polkit
            && mappedWithPatchedImports.security.polkit ? extraPolicies
          then
            mappedWithPatchedImports // {
              security = mappedWithPatchedImports.security // {
                polkit = builtins.removeAttrs mappedWithPatchedImports.security.polkit [ "extraPolicies" ];
              };
            }
          else
            mappedWithPatchedImports
    else
      value;
in
removePolkitExtraPolicies rawModule
