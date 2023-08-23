# rct-widget-extension

## Motivation

With the launch of Dynamic Island and it's attractive UI that can be used to display live activities and other UI, it made me motivated enough to use Dynamic Island with react-native. With lack of knowledge about this new feature, I thought this might be doable by creating a simple Native Module or Native Component but I was proven wrong, since Dynamic Island is used to show Live Activities and the Live Activities are shown with the help of Widgets. 

Now, the idea was to have a package which will have a widget extension as a target already prepared, so when user installs the package, we'll move that target to the user's xcode project and link it. So the user won't have to deal with native setup. Something similar to what we have here in [react-native-today-widget](https://github.com/matejkriz/react-native-today-widget/). So, why can't we use that package directly and why should we create a new one? The reason for that is, this package uses `NCWidgetProviding` which is [deprecated](https://developer.apple.com/documentation/notificationcenter/ncwidgetproviding?language=objc) as of iOS 14.

## Research And Development

With the above findings, I tried to create a Native Component that could wrap Swift View in UIViewRepresentable which then could be used in SwiftUI. This sounds good but UIViewRepresentable isn't [compatible](https://developer.apple.com/forums/thread/652042) with WidgetKit. Now, since this approach didn't work, I tried to understand how we can achieve this. One thing that occurred to me was, `if we have our View heirarchy in SwiftUI then we can safely use React Native to develop widgets`. Now this seems pretty much complex as it means to change the internals of React Native.

Before diving into that path I looked up internet and I found Software Mansion did [RnD](https://github.com/software-mansion-labs/react-native-swiftui) on SwiftUI renderer 2-3 years back, when SwiftUI wasn't mature. I also read their [blog](https://blog.swmansion.com/swiftui-renderer-for-react-native-2b62fda38c9b?gi=791620eb7a52) post about this RnD. After having an understanding from these resources, I realised for writing React Native Apps with SwiftUI renderer requires the app to be init with Software Mansion's version of React Native. Which users might not be investing in right away as there is possibility that this might not scale right away for production ready apps. Because there are some differences in for example, how touches are handled with SwiftUI ScrollView.

I was also thinking, since most of the users already have their App built with UIKit's view hierarchy, and if they want to have a widget now, so they won't be interested in taking a path to change to SwiftUI renderer and use Software Mansion's React Native version. They would go right away to develop widget in SwiftUI only. 

Then I realised if somehow, we allow the users to use their main app in UIKit's view hierarchy and still be able to use SwiftUI renderer for developing widgets in React Native, that would be awesome and a real game changer. It will allow the easier adoption of this SwiftUI renderer and also allow us to scale this gradually. By scaling I mean, if we consider Widget Target, there are less UI elements used in there, whereas if we compare main App Target, it uses many UI elements like ScrollView, Button etc.

Given that, I started working on laying out specs on how I want to achieve this. I thought of having a third party package, which would consume Pods from existing React Native and I will copy/ paste the required SwiftUI renderer files from Software Mansion's. This seemed like a straight forward way but believe me it wasn't. SM's version of SwiftUI renderer was built by copy/ pasting React Native's 0.64.0 and I started directly on React Native 0.71+ and tried to add files from SM's to my package. As soon as I did that, I ran into tons of errors. Most of the files had imports that were now removed and most of the code also had some method signature changed and new APIs added. I invested on fixing these issues for like 3 weeks but I was very badly stuck. So I decided to try running SM's repo directly and see even if it's working 😄. I know I should have tested it earlier.

 Anyways, their repo was running fine and I was glad that it's working, so I now have to figure out how can I follow my approach of having a third party package for SwiftUI renderer. At first, I also didn't know on which React Native version they did a fork, so I tried to find it out by checking the initial commit date and comparing it with React Native releases XD. I then found it they might have used something around 0.64.0. Then I created a third party package using [create-react-native-library](https://github.com/callstack/react-native-builder-bob) and having React Native at 0.64.0. With this, I was confident that SM's SwiftUI renderer can now reference the React Native's files easily. I started adding files from SM's to my package in `ios` directory and changing whatever required for example: Renaming Swift Header for imports. Once the moving of files was done, I tried to build the example app and voila, a lot of errors XD. There were still some files that couldn't be referenced as they were in React Native's internals. And why SM didn't have issues with it? Because they were using RN-Teseter to show their demo and all of the files were easily accessible from within React Native. And since, I was aiming it to be a stand alone package, which can leverage files from the installed React Native Pod.
 
 After analysing the errors, I added the reference to the imports by adding them to the `HEADER_SEARCH_PATHS` in `Podspec`. I also had to change a couple of imports to make it working. And finally, the example app was successfully built. This example app has `rct-widget-extension` as a dependency.
 
 With errors gone, now I created a Widget Target in example app and added the bundler path to the `TodayWidget.Swift`. I also added a `Widget.js` file in the root of example app. Once that was done, I ran the example app and the widget was being shown with the JSX from `Widget.js`, having view hierarchy in SwiftUI 🎉 Also, the main example app, which has it's view hierarchy in UIKit was also working fine side by side. 🚀
 
![Screenshot 2023-05-15 at 11 22 03 PM](https://github.com/hurali97/rct-widget-extension/assets/47336142/65877228-13bc-4006-a077-fca58837ab24)

 ## Component Details
 
 SM has following components in SwiftUI renderer:
 
 - Animation
 - Blur
 - Rect
 - Button
 - Circle
 - LinearGradient
 - Mask
 - ScrollView
 - Shadow

The following are also in SwiftUI renderer but they are registered as View, Image and Text in React Native, so they are imported from React Native itself:

 - View
 - Image ( Image can also be imported from SwiftUI, it's registered twice, one with name `Image` and other with `RSUIImage`)
 - Text

P.S: I assume they have used the same registration as they are the base elements and React Native does some magic work on them internally? So we can also leverage it? I tried adding a View to SwiftUI registry with different name and I was able to import it from SwiftUI. But then I removed it, since we can import from React Native, which under the hood uses our SwiftUI based View.

The cool part is that, when we are running main example app, React Native uses View, Text, Image from it's own registry and when we run Widget, React Native uses SwiftUI registry.

## Constraints

- This is working with React Native 0.64.0 but we want to keep up with latest React Native. ( Most important and complex )
- This is based on Fabric architecture and I don't know if we should support Paper.
- Fast Refresh doesn't work and we have to remove and then add widget, to see our changes. ( I had an approach but it sometimes work and sometimes not ** )
- Have a patch-package, which fixes issues like adding a bitwise operator to Yoga.cpp due to latest Xcode updates and commenting out #ifdef Android flag in `ReactCommon/react/renderer/attributedstring/conversions`. It also includes other files which are not meant to be added in patch-package like FBReactNativeSpec (which is auto-generated by React Native) but for temporary I am moving with patch-package. Ideally, we should have a script which changes the files we need.
- Anything else ??

** The approach is to call `WidgetCenter.shared.reloadTimelines` whenever the delegate method `handleJavaScriptDidLoadNotification` is called.

## Running

Clone this repo using:

`git clone https://github.com/hurali97/rct-widget-extension.git`

Then go to the `rct-widget-extension` dir and run `yarn or yarn install`.

Open the `example/ios/RctWidgetExtensionExample.xcworkspace` and run it. 

- If you are running App Target, once the app is running in simulator, press the home icon and add a widget on the home screen. You should see the Widget as shown in the SS above.
- If you are running Widget Target, once the widget is running in simulator, you should see the Widget as shown in the SS above.


## Trouble Shooting:

- If you are seeing the White UI for Widget even after adding it, try adding it again, it should work. The issue is that sometimes the bundle isn't loaded.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
