#
# Be sure to run `pod lib lint CKTableViewTransactionalDataSource.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CKTableViewTransactionalDataSource'
  s.version          = '0.1'
  s.summary          = 'Tableview datasource for CompoenentKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/leavez/CKTableViewTransactionalDataSource'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Leavez' => 'gaojiji@gmail.com' }
  s.source           = { :git => 'https://github.com/leavez/CKTableViewTransactionalDataSource.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.public_header_files = 'CKTableViewTransactionalDataSource/*.h'
  s.source_files = 'CKTableViewTransactionalDataSource/**/*'
  s.dependency "ComponentKit", '~> 0.2'
end
