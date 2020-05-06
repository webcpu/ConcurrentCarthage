# frozen_string_literal: true

require 'rake/testtask'

desc 'Build'
task :build do
  ruby 'main.rb'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

task default: :build
