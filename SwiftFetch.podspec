#
# Be sure to run `pod lib lint SwiftFetch.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftFetch'
  s.version          = '0.0.2'
  s.summary          = 'Wrapper For URLSession For Convenient Networking With Swift'

  s.description      = <<-DESC
Wrapper For URLSession For Convenient Networking With Swift
ToDo: Write more
                       DESC

  s.homepage         = 'https://github.com/yury-dymov/SwiftFetch'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yury@dymov.me' => 'yury@dymov.me' }
  s.source           = { :git => 'https://github.com/yury-dymov/SwiftFetch.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.0'

  s.source_files = 'SwiftFetch/Classes/**/*'
end
