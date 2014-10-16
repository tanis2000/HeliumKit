#
# Be sure to run `pod lib lint HeliumKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "HeliumKit"
  s.version          = "0.1.2"
  s.summary          = "HeliumKit is a lightweight framework that sits between your web services and the business logic of your app."
  s.description      = <<-DESC
                        It provides basic mapping to automate conversion from DTO coming from your web services into object models of your business domain. We decided to streamline the process by adopting some libraries and frameworks:

                        - PromiseKit to manage all the async code
                        - FMDB to store data in SQLite
                        - Mantle to convert models to and from JSON representation
                        - MTLFMDBAdapter to convert models into SQL statements to feed to FMDB

                        The main focus is to keep this framework as lightweight as possible and at the same time make it flexible enough for you to craft the perfect solution to your data transfer and storage layer. Many ideas come from RestKit as I've been using that framework for commercial apps before. But I've never been fond of Core Data as the storage architecture. I'm way too used to good old SQL statements and I can't live with the threading issues that you have to fight against when using Core Data. Core Data is great, but it's not for me.

                        HeliumKit can simply keep your data in in-memory models or it can write them to SQLite as needed. That's completely configurable. I tried to keep in mind the convention over configuration paradigm as I hate boilerplate code.
                        DESC
  s.homepage         = "https://github.com/tanis2000/HeliumKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Valerio Santinelli" => "santinelli@altralogica.it" }
  s.source           = { :git => "https://github.com/tanis2000/HeliumKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/santinellival'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*.{h,m}'
  #s.resources = 'Pod/Assets/*.png'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Mantle', '~> 1.5'
  s.dependency 'FMDB', '~> 2.3'
  s.dependency 'MTLFMDBAdapter', '~> 0.1'
  s.dependency 'PromiseKit/Promise', '~> 0.9'
  s.dependency 'PromiseKit/When', '~> 0.9'
  s.dependency 'PromiseKit/Until', '~> 0.9'
  s.dependency 'PromiseKit/Pause', '~> 0.9'

end
