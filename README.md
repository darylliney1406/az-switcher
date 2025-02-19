# az-switcher
Powershell script to ease the switching between Azure tenants and subscriptions

This tool requires the use of both AzCLI and Powershell Az module. If you do not have either installed the tool will install them for you.

To install.
1. Clone repo
2. run `.\az-switcher.ps1` to launch tool
3. run `.\az-switcher.ps1 -status` to get a quick connection status


If you want to make your life a little easier. Modify your powershell profile (run > `code $PROFILE`) to add the following lines. Save and reload your terminal.

`Set-Alias -Name azsw -Value "C:\path\to\az-switcher.ps1"`

You should now be able to run the tool by calling `azsw` or `azsw -status`