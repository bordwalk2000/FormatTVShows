# MediaFileManager PowerShell Module

## 📝 Description

This module is used to contain the different scripts and functions that are used in managing my Media library.

## ⚠️ Caution

I cannot recommend enough working off a copy your source files before running something against them that will result in any changes having to be manually undone. Use the Copy-FolderStructure function to create a copy source files and test against that to make sure you are happy with the desired outcome before running against your original1 files.

```powershell
Copy-FolderStructure './stargate sg1/'
````

## 💿 Installation

The MediaFileManager Module is published to the PowerShell Gallery. You can install it to your profile by running the following command.

```powershell
Install-Module -Name MediaFileManager
```

## 💽 Developer Instructions

If you want to run this module from source it can found at [GitHub](https://github.com/bordwalk2000/MediaFileManager).  The can be built with the ModuleBuilder module by running the following ps1 file.

```powershell
Start-ModuleBuild.ps1
```

This will package all code into files located in .\Output\MediaFileManager.  That folder is now ready to be installed, copy to any path listed in you PSModulePath environment variable and you are good to go!
