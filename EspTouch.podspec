Pod::Spec.new do |spec|
  spec.name = "EspTouch"
  spec.version = "1.0.0"
  spec.summary = "allow you to use smartconfig on ESP8266/Esp32 device"
  spec.homepage = "https://github.com/EspressifApp/EsptouchForIOS"
  spec.license = { type: 'MIT', file: 'ESPRESSIF_MIT_LICENSE_V1' }
  spec.authors = { "Espressif" => 'your-email@example.com' }
  spec.platform = :ios, "8.0"
  spec.source       = { :git => 'https://github.com/EspressifApp/EsptouchForIOS.git' }
  spec.source_files = "EspTouch/EspTouch/*.{h,m}"
end
