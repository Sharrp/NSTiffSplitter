Pod::Spec.new do |s|
  s.name     = "NSTiffSplitter"
  s.version  = "1.0.0"
  s.summary  = "Objective-C dynamic framework for viewing multipage tiff files on iOS devices."
  s.homepage = "https://github.com/Sharrp/NSTiffSplitter"
  s.license  = "MIT"

  s.authors = { "Anton Sharrp Furin" => "", "Tomas Sliz" => "" }

  s.platform = :ios, "8.0"

  s.source = { :git => "https://github.com/Sharrp/NSTiffSplitter.git", :tag => "#{s.version}" }

  s.source_files = "Source/NSTiffSplitter/*.{h,m}"
end

