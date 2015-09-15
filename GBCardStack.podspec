Pod::Spec.new do |s|
  s.name                   = 'GBCardStack'
  s.version                = '3.0.1'
  s.summary                = 'iOS UI paradigm for a stack of sliding cards.'
  s.homepage               = 'https://github.com/lmirosevic/GBCardStack'
  s.license                = 'Apache License, Version 2.0'
  s.author                 = { 'Luka Mirosevic' => 'luka@goonbee.com' }
  s.platform               = :ios, '7.0'
  s.source                 = { git: 'https://github.com/lmirosevic/GBCardStack.git', tag: s.version.to_s }
  s.source_files           = 'GBCardStack/GBCardStackController.{h,m}', 'GBCardStack/UIViewController+GBCardStack.{h,m}', 'GBCardStack/GBCardStackAnalyticsModule.{h,m}', 'GBCardStack/GBCardStack.h'
  s.public_header_files    = 'GBCardStack/GBCardStackController.h', 'GBCardStack/UIViewController+GBCardStack.h', 'GBCardStack/GBCardStackAnalyticsModule.h', 'GBCardStack/GBCardStack.h'
  s.requires_arc           = true

  s.dependency 'GBAnalytics', '~> 3.0'
  s.dependency 'GBToolbox'
end
