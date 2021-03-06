Pod::Spec.new do |s|
    s.name             = 'WolfImage'
    s.version          = '4.0.2'
    s.summary          = 'Tools for working with images in iOS and macOS.'

    s.homepage         = 'https://github.com/wolfmcnally/WolfImage'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Wolf McNally' => 'wolf@wolfmcnally.com' }
    s.source           = { :git => 'https://github.com/wolfmcnally/WolfImage.git', :tag => s.version.to_s }

    s.source_files = 'Sources/WolfImage/**/*'

    s.swift_version = '5.0'

    s.ios.deployment_target = '9.3'
    s.macos.deployment_target = '10.13'
    s.tvos.deployment_target = '11.0'

    s.module_name = 'WolfImage'

    s.dependency 'WolfCore'
    s.dependency 'WolfColor'
    s.dependency 'WolfGeometry'
end
