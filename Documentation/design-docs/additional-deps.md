# Additional-deps

## Summary
This document describes current (2.0) and proposed (2.1) behavior for "light-up" scenarios regarding additional-deps functionality.

The `deps.json` file format specifies assets including managed assemblies, resource assemblies and native libraries to load.

Every applicaton has its own `<app>.deps.json` file which is automatically processed. If an application needs additional deps files, typically for "lightup" extensions, it can specify that by:
- The `--additional-deps` command line option
- If this is not set, the `DOTNET_ADDITIONAL_DEPS` environment variable is used

The value can be a combination of:
- A path to a deps.json file
- A path to a folder which can contain several deps.json files
separated by a path delimiter (e.g. `;` on Windows, `:` otherwise).

When additional-deps specifies a folder:
- The resulting folder can have more than one deps.json files; all will be processed
- If there are several frameworks (e.g. Microsoft.AspNetCore.App, Microsoft.AspNetCore.All, Microsoft.NETCore.App) then each will be processed

## 2.0 behavior
When additional-deps specifies a folder, the subfolder must follow a naming convention of `shared/<framework_name>/<requested_framework_version>`

The semantics of `requested_framework_version` is that it matches exactly the "version" specified by the `runtimeconfig.json` in its "framework" section:
```
{
  "runtimeOptions": {
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "2.0.0"
     }
  }
}
```
So even if a roll-forward on a framework occurred here to "2.0.1", the directory structure must match the "requested" version ("2.0.0" in this case).

Note that the app and each framework has its own `runtimeconfig.json` setting, which can be different because each defines the framework "name" and "version" for the next lowest framework which don't have to have the same "version".

### 2.0 issues
The primary issue is the use of the `requested_framework_version` folder naming convention:
- Since it does not take into account newer framework versions, any "lightup" extensions must co-release with new framework(s) releases which is especially an issue with frequent patch releases. However, this is somewhat mitigated because most applications in their `runtimeconfig.json` do not target an explicit patch version, and just target `major.minor.0`
- Since it does not take into account older framework versions, a "lightup" extensions should install all previous versions of deps files. Note that since some previous versions may require different assets in the deps.json file, for example every minor release, this issue primarily applies to frequent patch versions.

The proposal for this is to "roll-backwards" starting with the "found" version.

A secondary issue with with the store's naming convention for framework. It contains a path such as:
   `\dotnet\store\x64\netcoreapp2.0\microsoft.applicationinsights\2.4.0`
where 'netcoreapp2.0' is a "tfm" (target framework moniker). During roll-forward cases, the tfm is still the value specified in the app's runtimeconfig. The host only includes store folders that match that tfm, so it may not find packages from other deps files that were generated off a different tfm. In addition, with the advent of multiple frameworks, it makes it cumbersome to be forced to install to every tfm because multiple frameworks may use the same package, and because each package is still identified by an exact version.

The proposal for this is to add an "any" tfm.

Finally, a third issue is there is no way to turn off the global deps lightup (via `%DOTNET_ADDITIONAL_DEPS%`) for a single application if they run into issues with pulling in the additional deps. If the environment variable is set, and an application can't load because of the additional lightup deps, and the lightup isn't needed, there should be a way to turn it off so the app can load. One (poor) workaround would be to specify `--additional-deps` in the command-line to point to any empty file, but that would only work if the command line can be used in this way to launch the application.

The proposal for this is to add a new runtimeconfig.json knob to disable `%DOTNET_ADDITIONAL_DEPS%`.

## 2.1 proposal (roll-backwards)
In order to prevent having to co-release for roll-forward cases, and deploy all past versions, the followng rules are proposed:
1) Instead of `requested_framework_version`, use `found_framework_version`

Where "found" means the version that is being used at run time including roll-forward. For example, if an app requests `2.1.0` of `Microsoft.NETCore.App` in its runtimeconfig.json, but we actually found and are using `2.2.1` (because there were no "compatible" versions installed from 2.1.0 to 2.2.0), then look for the deps folder `shared/Microsoft.NETCore.App/2.1.1` first.

2) If the `found_framework_version` folder does not exist, find the next closest by going "backwards" in versioning
3) The next closest version only includes a lower minor or major if enabled by "roll-forward-by-no-candidate-fx"

The "roll-forward-by-no-candidate-fx" option has values (0=off, 1=minor, 2=minor\major) and is specified by:
- `%DOTNET_ROLL_FORWARD_ON_NO_CANDIDATE_FX%` environment variable
-	`rollForwardOnNoCandidateFx` in runtimeconfig.json
-	`--roll-forward-on-no-candidate-fx` command line option

where 1 (minor) is the default.

Similar to `applyPatches`, the app may or may not want to tighten or loosen the range of supported frameworks. The default of `minor` seems like a good fit for additional-deps.

4) Similar to roll-forward, a release version will only "roll-backwards" to release versions, unless no release versions are found. Then it will attempt to find a compatible pre-release version.

Note: some "roll-backwards" semantics are different than roll-forward semantics. The "apply patches" functionality that exists in roll-forward doesn't make sense here since we are going "backwards" and the nearest (most compatible) version already has patches applied and we don't want to take older patches. In addition, roll-forward will not go from pre-release to release (since breaking changes on new features may occur during pre-release-to-release versions), but again that doesn't make sense here since we are going backwards to pre-existing (compatible) versions.

## 2.1 proposal (add an "any" tfm to store)
For example,
    `\dotnet\store\x64\any\microsoft.applicationinsights\2.4.0`
    
The `any` tfm would be used if the specified tfm (e.g. netcoreapp2.0) is not found:    
    `\dotnet\store\x64\netcoreapp2.0\microsoft.applicationinsights\2.4.0`

_Note: doesn't this make "uninstall" more difficult? Because multiple installs may write the same packages and try to remove packages that another installer created?_

## 2.1 proposal (add runtimeconfig knob to to disable `%DOTNET_ADDITIONAL_DEPS%`)
Add an `additionalDepsLookup` option to the runtimeconfig with these values:

  0) The `%DOTNET_ADDITIONAL_DEPS%` is not used
  1) `DOTNET_ADDITIONAL_DEPS` is used (the default)

## Long-term thoughts
A lightup "extension" could be considered an application, and have its own `runtimeconfig.json` and `deps.json` file next to its corresponding assembly(s). In this way, it would specify the target framework version and thus compatibility with the hosting application could be established. Having an app-to-app dependency in this way is not currently supported.

It could be supported by entending the concept of "multi-layered frameworks" like we have with Microsoft.AspNetCore.App, Microsoft.AspNetCore.All, Microsoft.NETCore.App, where they each have their own runtimeconfig.json and deps.json files.

Adding support for app-to-app dependencies would imply adding a "horizontal" hierarchy, and introducing a "graph reconcilation" phase that would need to be able to collapse several references to the same app or framework when they have different versions.

Similar to additional-deps, the extension apps could "light up" by (for example) an "additional-apps" host option or environment variable.
