# BuildSystemPlugins

With the release of latest RC from Xcode 13.4 we can now have pre-/post-build scripts on the package level

This package introduces SwiftGen, SwiftLint and Sourcery to the DeliveryCheckMultiProblem package

Source file generation, as in SwiftGen generation for the localization, images, storyboards and as in Sourcery generating mocks in a Generated folder are directly saved in the derived data folder for the target.. so you won't see it but it's in the build

Two use cases for Mocks generation:

- One for a protocol in the interface mocked in the mocks target
- One for a protocol in the implementation mocked in the unit test and snapshot test target (say bye bye to writing duplicate mocks)

Main difference between cuckoo and Sourcery is that Sourcery does not force us to use a runtime library to test things.. it's merly only writing the mocks for us

Swiftlint rules for errors and warnings are all enforced as warnings only on the source code of the target(s) you're building and would require fixing before you can build

