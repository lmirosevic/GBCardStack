Pod::Spec.new do |s|
  s.name                   = 'GBCardStack'
  s.version                = '1.0.2'
  s.summary                = 'iOS UI paradigm for a stack of sliding cards.'
  s.homepage               = 'https://github.com/lmirosevic/GBCardStack'
  s.license                = 'Apache License, Version 2.0'
  s.author                 = { 'Luka Mirosevic' => 'luka@goonbee.com' }
  s.platform               = :ios, '6.0'
  s.source                 = { git: 'https://github.com/lmirosevic/GBCardStack.git', tag: s.version.to_s }
  s.source_files           = 'GBCardStack/GBCardStackController.{h,m}', 'GBCardStack/UIViewController+GBCardStack.{h,m}', 'GBCardStack/GBCardStack.h'
  s.public_header_files    = 'GBCardStack/GBCardStackController.h', 'GBCardStack/UIViewController+GBCardStack.h', 'GBCardStack/GBCardStack.h'
  s.requires_arc           = true
  # s.frameworks             = 'SystemConfiguration', 'CoreData', 'CoreGraphics', 'QuartzCore'
  # s.libraries              = 'z', 'icucore', 'sqlite3'

  s.dependency 'GBAnalytics', '~> 2.5'
  s.dependency 'GBToolbox'
end
