## Usage

This package is not on NPM yet, so you have to install it manually.

>IMPORTANT: This package is only for iOS and only available on new architecture (Fabric). 
### Installation

- Clone the repository and run `yarn` or `yarn install` in the root directory.
- Run `npm pack` in the root directory to build the package, copy and paste that tarball in your project and run the following command from the root of your project:

```bash
yarn add ./rct-widget-extension-0.1.0.tgz
```

#### Automatic Setup
- Once the installation is completed, run the following command from the root of your project. This command will allow you to automatically create Widget Target with everything setup for using Widgets. It will also update the podfile with required dependencies and configurations.

If you want to update `Podfile` manually, pass false to the `--updatePodfile` flag and follow the steps from manual section.:

```bash
yarn setup_widget --widgetTargetName AbcWidgetExtension --xcodeProjectPath ./ios/DemoWidgetRN.xcodeproj --bundleID org.reactjs.native.example.DemoWidgetRN --updatePodfile true
```

> This will add the required files in your project, the required dependencies and the widget target automatically.

#### Manual Setup

To be Added Later

-- --


| Option          | Description                                                                                                                                                  | Usage                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| `widgetTargetName`      | Name of the Widget Target you want to create                                                                                         | `--widgetTargetName AbcWidgetExtension`                 |
| `xcodeProjectPath`           | Path to your xcode project                                                                                                             | `--xcodeProjectPath ./ios/DemoWidgetRN.xcodeproj`                    |
| `bundleID`           | Bundle id of your App                                                                                                            | `--bundleID org.reactjs.native.example.DemoWidgetRN`                    |
| `updatePodfile`           | Whether this script should update podfile                                                                                                             | `--updatePodfile true`                    |

-- --

- Finally to install the Pods, run the following command from the root of your project:

```bash
cd ios && RCT_NEW_ARCH_ENABLED=1 bundle exec pod install
```
