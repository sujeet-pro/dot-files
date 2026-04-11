---
title: macOS System Defaults
---

# macOS System Defaults

The `macos` Ansible role applies all of these system defaults. After applying, Dock, Finder, and SystemUIServer are automatically restarted.

## Screenshots

| Key                              | Value               | Effect                              |
| -------------------------------- | -------------------- | ----------------------------------- |
| `com.apple.screencapture location` | `~/screen-captures` | Save screenshots to custom folder  |
| `com.apple.screencapture type`   | `png`                | PNG format (lossless)               |
| `com.apple.screencapture disable-shadow` | `true`       | No window shadow in screenshots     |

## Finder

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `AppleShowAllFiles`                        | `true`  | Show hidden files                         |
| `FXDefaultSearchScope`                     | `SCcf`  | Search current folder by default          |
| `FXEnableExtensionChangeWarning`           | `false` | No warning when changing file extensions  |

## Dock

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `autohide`                                 | `true`  | Auto-hide the Dock                        |
| `tilesize`                                 | `36`    | Smaller icon size                         |
| `mineffect`                                | `scale` | Scale effect for minimizing windows       |
| `show-recents`                             | `false` | Hide recent apps section                  |
| `autohide-delay`                           | `0`     | No delay before Dock appears              |

## Keyboard

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `KeyRepeat`                                | `2`     | Fastest key repeat rate                   |
| `InitialKeyRepeat`                         | `15`    | Shortest delay before repeat starts       |
| `ApplePressAndHoldEnabled`                 | `false` | Disable press-and-hold, enable key repeat |

## Trackpad

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `com.apple.trackpad.scaling`               | `2.5`   | Faster tracking speed                     |

## Mission Control

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `mru-spaces`                               | `false` | Do not rearrange Spaces by most recent use|
| `expose-animation-duration`                | `0.1`   | Faster Mission Control animation          |

## Desktop Services

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `DSDontWriteNetworkStores`                 | `true`  | No `.DS_Store` on network volumes         |
| `DSDontWriteUSBStores`                     | `true`  | No `.DS_Store` on USB volumes             |

## UI Behavior

| Key                                              | Value   | Effect                                    |
| ------------------------------------------------ | ------- | ----------------------------------------- |
| `NSNavPanelExpandedStateForSaveMode`             | `true`  | Expanded save panel by default            |
| `NSNavPanelExpandedStateForSaveMode2`            | `true`  | Expanded save panel (alternate)           |
| `PMPrintingExpandedStateForPrint`                | `true`  | Expanded print panel by default           |
| `PMPrintingExpandedStateForPrint2`               | `true`  | Expanded print panel (alternate)          |
| `NSDocumentSaveNewDocumentsToCloud`              | `false` | Save to disk by default, not iCloud       |
| `LSQuarantine`                                   | `false` | No "downloaded from internet" dialog      |

## Security

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `askForPassword`                           | `1`     | Require password after sleep              |
| `askForPasswordDelay`                      | `0`     | Require password immediately              |

## TextEdit

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `RichText`                                 | `0`     | Plain text mode by default                |
| `PlainTextEncoding`                        | `4`     | UTF-8 encoding                            |
| `PlainTextEncodingForWrite`                | `4`     | UTF-8 encoding for saving                 |

## Activity Monitor

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `IconType`                                 | `5`     | Show CPU usage in Dock icon               |
| `ShowCategory`                             | `0`     | Show all processes                        |

## Safari

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `IncludeDevelopMenu`                       | `true`  | Enable the Develop menu                   |

## Chrome

| Key                                        | Value   | Effect                                    |
| ------------------------------------------ | ------- | ----------------------------------------- |
| `AppleEnableSwipeNavigateWithScrolls`      | `false` | Disable swipe navigation                  |

## Default Applications

These are set via the playbook and system tools:

| Role       | Application | How set                                    |
| ---------- | ----------- | ------------------------------------------ |
| Browser    | Chrome      | `defaultbrowser` CLI                       |
| Terminal   | Ghostty     | Configured via Ghostty preferences         |
| Editor     | Zed         | `$EDITOR` and `$VISUAL` env vars in `.zshenv` |
