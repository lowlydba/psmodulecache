param (
   [string[]]$Module,
   [ValidateSet("KeyGen","ModulePath", "SaveModule")]
   [string]$Type,
   [string]$Shell
)
$shells = $Shell.Split(",").Trim()
switch ($Type) {
   'KeyGen' {
      # all this splitting and joining accomodates for powershell and pwsh
      Write-Output "$env:RUNNER_OS-v4.5-$($shells -join "-")-$(($Module.Split(",") -join '-').Replace(' ',''))"
   }
   'ModulePath' {
      foreach ($module in $modules) {
         $item, $version = $module.Split(":")
         Write-Output $item
         if ($env:RUNNER_OS -eq "Windows") {
            $modpath = "$env:ProgramFiles\PowerShell\Modules\$item"
            if ($Shell -eq "powershell") {
               $modpath.Replace("PowerShell","WindowsPowerShell")
            } elseif ($Shell -eq "pwsh") {
               $modpath
            } else {
               $modpath.Replace("PowerShell","*PowerShell*"))
            }
         } else {
            $modpath = "/usr/local/share/powershell/Modules/$item"
            $null = sudo chown -R runner $modpath
            $modpath
         }
      }
   }
   'SaveModule' {
      $moduleinfo = Import-CliXml -Path (Join-Path $home -ChildPath cache.xml)
      Write-Output "Trusting repository PSGallery"
      Set-PSRepository PSGallery -InstallationPolicy Trusted
      $modules = $moduleinfo.Modules.Split(",").Trim()
      $shells = $moduleinfo.Shell.Split(",").Trim()
      $force = [bool]($moduleinfo.force)
      $allowprerelease = [bool]($moduleinfo.allowprerelease)

      foreach ($module in $modules) {
         foreach ($psshell in $shells) {
            if ($env:RUNNER_OS -eq "Windows") {
               $modpath = "$env:ProgramFiles\PowerShell\Modules"
               if ($psshell -eq "powershell") {
                  $modpath = $modpath.Replace("PowerShell","WindowsPowerShell")
               }
            } else {
               $modpath = "/usr/local/share/powershell/Modules"
            } 
            Write-Output "Saving module $module on $psshell to $modpath"
            $item, $version = $module.Split(":")
            if ($version) {
               Save-Module $item -RequiredVersion $version -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $modpath
            } else {
               Save-Module $item -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $modpath
            }
         }
      }
   }
}
