## 🚀 Uage

I have an complete [app](https://github.com/AbodiDawoud/SysKit/tree/main/Example) showcasing the package, here a quick snippet:

```swift
// Access all system info via SystemSnapshot
let osInfo = SystemSnapshot.os
print("macOS Board-ID:", osInfo.boardID)

// Check if the current user is admin
let userInfo = SystemSnapshot.user
print("Is Admin:", userInfo.isCurrentUserAdmin)

// Open Software Update pane
SystemSnapshot.os.launchSoftwareUpdate()
```

## Preview
<img width="1165" height="981" alt="Screenshot-1" src="https://github.com/user-attachments/assets/a0199be4-33cb-4dc0-b89b-1149b3290b39" />
<img width="1165" height="830" alt="Screenshot-2" src="https://github.com/user-attachments/assets/97923f50-9d25-4efb-ace2-6147d1835893" />
