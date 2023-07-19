#
# Be sure to run `pod lib lint VTComponents.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'VTComponents'
    s.version          = '2.0.3'
    s.summary          = 'Data / Domain Layer Components / Utilities common to macOS / iOS'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'This library contains helpers, utilities of Data / Domain Layer Components common to macOS / iOS'
    
    s.homepage         = 'https://git.csez.zohocorpin.com/vtouchzoho/VTComponents.git'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :text => 'LICENSE' }
    s.author           = { 'rahul.t' => 'rahul.t@zohocorp.com' }
    s.source           = { :git => 'https://git.csez.zohocorpin.com/vtouchzoho/VTComponents.git', :tag => s.version }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.platform = :osx
    s.osx.deployment_target = "10.11"
    s.ios.deployment_target = "8.0"
    s.watchos.deployment_target = "3.0"
    s.tvos.deployment_target = "9.0"

    s.source_files = 'native/VTComponents/**/*.{swift}'
    s.frameworks = 'Foundation', 'CoreGraphics' # Coregraphics required for CGFloat support in watchOS
    s.module_name = 'VTComponents'
    s.swift_version = "4.2"
    end
