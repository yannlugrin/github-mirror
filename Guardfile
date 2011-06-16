# encoding: utf-8

guard 'bundler' do
  watch('Gemfile')
end

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})  { 'spec' }
  watch('spec/spec_helper.rb')        { 'spec' }
  watch('config/config.yml')          { 'spec' }
end
