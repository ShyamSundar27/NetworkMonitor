Pod::Spec.new do |s|
  s.name         = 'NetworkMonitor'
  s.version      = '1.0.2'
  s.summary      = 'NetworkMonitor is used to monitor network calls'
  s.description  = 'NetworkMonitor is used to monitor network calls in the application'

  s.homepage     = "https://github.com/ShyamSundar27/NetworkMonitor"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'ShyamSundar27' => 'shyamsuper50@gmail.com' }
  s.source       = { :git => 'https://github.com/ShyamSundar27/NetworkMonitor.git' , :tag => '1.0.2'}

  s.platform     = :ios, '11.0'

  s.source_files = 'native/NetworkMonitor/NetworkMonitor/*.swift'
  
  
  s.frameworks = ['Foundation', 'Cocoa']
  s.swift_version = '4.0'
  s.dependency 'VTComponents', '~> 2.0.3'
  s.dependency 'ZNetworkManager', '~> 2.0.0'
  s.dependency 'ZSqliteHelper', '~> 1.0.18'

end

