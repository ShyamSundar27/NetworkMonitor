#
# Be sure to run `pod lib lint ZSqliteHelper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'ZSqliteHelper'
    s.version          = '1.0.0'
    s.summary          = 'Sqlite helper for macOS / iOS'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'This library contains helpers, utilities of Data / Domain Layer Components common to macOS / iOS'
    
    s.homepage         = 'https://git.csez.zohocorpin.com/vtouchzoho/Apple/common/zsqlitehelper.git'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :text => 'LICENSE' }
    s.author           = { 'robin.rajasekaran' => 'robin.rajasekaran@zohocorp.com' }
    s.source           = { :git => 'https://git.csez.zohocorpin.com/vtouchzoho/Apple/common/zsqlitehelper.git', :commit => '757d752' }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.platform = :osx
    s.osx.deployment_target = "10.11"
    s.ios.deployment_target = "8.0"
    s.watchos.deployment_target = "3.0"
    s.tvos.deployment_target = "9.0"

    s.source_files = 'native/ZSqliteHelper/ZSqliteHelper/*.{swift}'
    s.frameworks = 'Foundation'
    s.module_name = 'ZSqliteHelper'
    s.swift_version = "4.2"
    s.dependency 'VTDB/Lite', '~> 0.5'
end
    

