# AlphaScript
![GitHub](https://img.shields.io/github/license/NovaDynamics/alphascript.svg)

AlphaScript lets you easily manage your scripts and adds automatically some useful and powerful functions.

## Features
- One starting point for all scripts
- Simplified use for non-developers
- Handles script loops out-of-the-box
- User-friendly navigation

And more features in development.

## Get Started
Download the file alphascript.ps1 from the src-folder of this repository. Open the file in PowerShell ISE or an text editor and define a valid path to a folder as `basepath` (line 15).

### Folder Structure
After you defined your `basepath`, you can start building your structure with subfolders. Every folder within the `basepath` is represented as a category in AlphaScript. To work properly, the folders needs to be named like `KEY-NAME`. Note that you can also use "-" in your `NAME` (as AlphaScript only splits by the first occurrence).

`KEY`
This represents the access key in AlphaScript. (Numeric)

`NAME`
This represents the category name in AlphaScript. (Alphanumeric)

![AlphaScript Structure](https://github.com/NovaDynamics/alphascript/blob/master/images/structure.png?raw=true)

### Script Structure
Now you can add the scripts you want to be provided in AlphaScript. Although we tried to keep the process as simple as possible, some small modification and additions to the scripts are necessary: The scripts (usually .ps1-files) has to be transformed into PowerShell-Modules and we need to extend the scripts with some boilerplate code. Don't panic: A manifest-file for the module is not required as it would be exaggerated for our needs and AlphaScript doesn't need it.

So lets say we have the following script:

`\HelloWorld.ps1`
```javascript
$name = Read-Host "your name"
Write-Host "hello $($name)"
```

Now first we create a folder with the same name as the file, move the file into that folder and rename the file extension from .ps1 to .psm1:

`\HelloWorld\HelloWorld.psm1`

Then open the file, add the function `ASConfig` and wrap the whole script code into the function `ASMain`:

```javascript
Function ASConfig {
    return @{
        KEY  = 1
        NAME = 'Hello World'
    }
}

Function ASMain {
  $name = Read-Host "your name"
  Write-Host "hello $($name)"
}
```

**NOTE:** The key "x" is intercepted by AlphaScript for navigating back, so you can not use it as an input in your script. We know it's a little bit ugly, but thought it would be the best and most intuitive way. Anyway, feel free to change the character or the whole navigation mechanism if really necessary...

Within the function `ASConfig` you define the `KEY` and `NAME` for the script. It's represented in AlphaScript like the folders you previously created under your `basepath`.

`KEY`
This represents the access key in AlphaScript. (Integer)

`NAME`
This represents the script name in AlphaScript. (String)

That's all! Now start AlphaScript and check out the result.

## Example
Download the ZIP from the example-folder and extract the content. Set the `basepath` in alphascript.ps1 to point to the top-most extracted folder and start AlphaScript.

**NOTE:** The scripts from the archive are not part of AlphaScript. They are just for demonstrational purposes.

We borrowed the scripts in the example from the following repositories:
- CeasarCipher by https://github.com/mikepfeiffer/PowerShell
- GetComputerInfo by https://github.com/lazywinadmin/PowerShell
- GetFolderInformations by https://github.com/RamblingCookieMonster/PowerShell
- GetMappedDrives by https://github.com/gangstanthony/PowerShell

## License
This project is licensed under the terms of the MIT license.