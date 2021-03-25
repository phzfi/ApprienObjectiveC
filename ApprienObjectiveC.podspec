#
#  Be sure to run `pod spec lint ApprienObjectiveC.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #  Apprien port to objective-c

  spec.name         = "ApprienObjectiveC"
  spec.version      = "0.0.1"
  spec.summary      = "Apprien pricing engine port to objective-c"

  spec.description  = "Apprien pricing engine port to Objective-c. More info Apprien.com"

  spec.homepage     = "http://Apprien.com"
  

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = { :type => "MIT", :file => "./LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "MikaelKorpinen" => "53366205+MikaelKorpinen@users.noreply.github.com" }
  # Or just: spec.author    = "MikaelKorpinen"
  # spec.authors            = { "MikaelKorpinen" => "53366205+MikaelKorpinen@users.noreply.github.com" }


   spec.platform     = :ios, "9.3"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  spec.source       = { :git => 'https://github.com/phzfi/ApprienObjectiveC.git', :tag => 'v0.0.1-alpha.1' }
  #spec.source       = { :git => 'https://github.com/phzfi/ApprienObjectiveC.git', :branch => 'fix-issue-cannot-find-curl-and-remove-unwanted-diagram' }
  

  spec.source_files  = "apprien-objective-c-sdk", "apprien-objective-c-sdk/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"


spec.framework  = "libcurl"
spec.library='curl.tbd'
spec.ios.vendored_frameworks = 'libcurl.tbd'


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end
