# frozen_string_literal: true

require 'pathname'
require 'open3'

# xcode-select
def check
  puts 'Check'
  cmd = 'xcode-select --version'
  stdout, _stderr, _status = Open3.capture3(cmd)

  # rubocop:disable Layout/LineLength
  raise "xcode-select is not installed. Please execute the command below to install it.\nxcode-select install" unless stdout.include? 'xcode-select version '
  # rubocop:enable Layout/LineLength
end

# clone
def clone
  puts 'Clone'
  Dir.chdir parent_path
  cmd = 'git clone https://github.com/Carthage/Carthage.git'
  _stdout, stderr, status = Open3.capture3(cmd)

  raise 'Failed to clone.' unless is_cloned?(status) || was_cloned?(stderr)
end

# rubocop:disable Style/NumericPredicate
# rubocop:disable Naming/PredicateName
def is_cloned?(status)
  status == 0
end
# rubocop:enable Naming/PredicateName

def was_cloned?(stderr)
  stderr.include?(carthage_exists_error) && File.file?(project_file_path)
end

# rubocop:disable Layout/LineLength
def carthage_exists_error
  "fatal: destination path 'Carthage' already exists and is not an empty directory."
end
# rubocop:enable Layout/LineLength

# checkout
def checkout
  puts 'Checkout'
  Dir.chdir carthage_path
  cmd = 'git checkout tags/' + carthage_tag
  _stdout, _stderr, status = Open3.capture3(cmd)
  is_checkouted = status == 0

  raise 'Failed to checkout tags/' + carthage_tag unless is_checkouted
end
# rubocop:enable Style/NumericPredicate

# patch
def patch
  puts 'Patch'
  # raise "Failed to patch."
  path = project_file_path
  code = File.read(path)
  result = replacements.inject(code) { |r, xs| r.gsub(xs[0], xs[1]) }
  result += flatten_strategy_extension
  File.write(path, result)
end

def parent_path
  Pathname(__dir__).parent.to_s
end

def carthage_path
  parent_path + '/Carthage/'
end

def project_file_path
  carthage_path + 'Source/CarthageKit/Project.swift'
end

# rubocop:disable Layout/LineLength
def source
  "			.flatMap(.concat) { dependency, version -> SignalProducer<((Dependency, PinnedVersion), Set<Dependency>, Bool?), CarthageError> in
            .flatMap(.concat) { dependency, version -> BuildSchemeProducer in
                let dependencyPath = self.directoryURL.appendingPathComponent(dependency.relativePath, isDirectory: true).path
                if !FileManager.default.fileExists(atPath: dependencyPath) {
                    return .empty
                }
"
end
# rubocop:enable Layout/LineLength

def flatten_strategy_extension
  "extension FlattenStrategy {
    static let maxConcurrent: FlattenStrategy = {
        let n = UInt(ProcessInfo().processorCount * 2)
        return FlattenStrategy.concurrent(limit: n)
    }()
}
"
end

def replacements
  [
    ['.flatMap(.concat) { dependency, version -> BuildSchemeProducer',
     '.flatMap(.maxConcurrent) { dependency, version -> BuildSchemeProducer'],
    ['.flatMap(.concat) { dependency, version -> SignalProducer',
     '.flatMap(.maxConcurrent) { dependency, version -> SignalProducer'],
    [flatten_strategy_extension, '']
  ]
end

def carthage_tag
  `git tag --sort=committerdate | tail -1`
end

# install
def install
  puts 'Build & Install'
  Dir.chdir carthage_path
  cmd = 'make install'
  system cmd
end

# main
def main
  check
  clone
  checkout
  patch
  install
rescue Exception => e
  puts e
end

main
