Pod::Spec.new do |s|
  s.name         = 'NetworkMonitor'
  s.version      = '1.0.0'
  s.summary      = 'NetworkMonitor is used to monitor network calls'
  s.description  = 'NetworkMonitor is used to monitor network calls in the application'

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Shyam Sundar J' => 'shyamsundar.ja@zohocorp.com' }
  s.source       = { :path => '.' }

  s.platform     = :ios, '11.0'

  s.source_files = 'native/NetworkMonitor*.swift'
  
  
  s.frameworks = ['Foundation', 'Cocoa']
  s.swift_version = '4.0'
  
  
end

