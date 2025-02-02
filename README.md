# 👨🏻‍💻 Make Enrollment User local Admin 👨🏻‍💻

This script can be deployed through Microsoft Intune to an Windows device to make the enrollment user a local administrator on the device. Similar to the option in Windows Autopilot but with this you can change the user level anytime later in the same way.

## Prerequisites

- Microsoft Intune
- Managed Windows Client

## How to?

Create a .INTUNEWIN from this repo and deploy it as an app in Microsoft Intune
Then upload it like this to your Intune environment and assign it to a group of users which should become local admin on their devices - they need to have them enrolled so that the detection can match.

### Program setup
![](/intune-setup.png)
- Install: ```C:\Windows\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -Command .\INSTALL-Client-LocalAdmin.ps1 -install```
- Uninstall: ```C:\Windows\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -Command .\INSTALL-Client-LocalAdmin.ps1 -uninstall```
- Return Code 0: ```0```

### Requirements
![](/intune-requirements.png)
- Script name: ```requirements.ps1```
- Output data: ```String```
- Operator: ```Equals```
- Value: ```OK```

### Detection
![](/intune-detection.png)

## 🤝 Contributing

Before making your first contribution please see the following guidelines:
1. [Semantic Commit Messages](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)
1. [Git Tutorials](https://www.youtube.com/playlist?list=PLu-nSsOS6FRIg52MWrd7C_qSnQp3ZoHwW)
1. [Create a PR from a pushed branch](https://learn.microsoft.com/en-us/azure/devops/repos/git/pull-requests?view=azure-devops&tabs=browser#from-a-pushed-branch)


---

Made with ❤️ by [Niklas Rast](https://github.com/niklasrst)