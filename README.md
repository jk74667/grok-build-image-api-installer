# Grok Build image API installer

This public repository contains only the PowerShell bootstrap installer. The
patched Grok Build source and Windows executable remain in the private
[`grok-build-image-api`](https://github.com/jk74667/grok-build-image-api)
repository. Installation requires GitHub access to that repository; Git for
Windows may open a sign-in window.

Run this single command in PowerShell on Windows x64:

```powershell
irm https://raw.githubusercontent.com/jk74667/grok-build-image-api-installer/main/install.ps1 | iex
```

The installer backs up an existing `~/.grok/bin/grok.exe` as
`~/.grok/bin/grok-previous.exe`, installs the patched 1.0.45 executable as
`grok.exe`, and adds that directory to the user `PATH`. It disables the official
auto-updater so it cannot replace the patched executable. It prompts for the
image-only PackyAPI key and base URL, saves them as user environment variables,
and leaves chat credentials unchanged. The key is never included in this public
repository or shown in installer output.

After installation, run `grok --version`, then start `grok` and try
`/imagine 고품질 Android 앱 배경 이미지`. PackyAPI-backed image editing remains
unsupported until its request format is confirmed.
