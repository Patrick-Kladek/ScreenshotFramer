class Screenshotframercli < Formula
    desc "With Screenshot Framer you can easily create nice-looking and localized App Store Images."
    homepage "https://github.com/IdeasOnCanvas/ScreenshotFramer"
    url "https://github.com/IdeasOnCanvas/ScreenshotFramer.git",
    :branch => "enhancement/homebrew",
    :revision => "8a066b17e13bab02e28653c8825f39295b08354d"
    version "1.0"
    revision 1

    depends_on :xcode => ["10.0", :build]

    def install
        system "ln -sf /usr/bin/true ./.tools/SwiftLint/swiftlint" # SwiftLint is not working properly when run inside brew install, not sure why
        xcodebuild "-project", "Screenshot Framer.xcodeproj",
        "-scheme", "Screenshot-Framer-CLI",
        "DSTROOT=build/install",
        "SYMROOT=build",
        "INSTALL_PATH=/bin",
        "install"
        bin.install "build/install/bin/Screenshot-Framer-CLI"
    end

    test do
    system "#{bin}/Screenshot-Framer-CLI -v"
end
end
