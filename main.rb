require 'pathname'
require 'open3'

# xcode-select
def checkXcodeCommandLineTools
  puts "Check"
  cmd = "xcode-select --version"
  stdout, stderr, status = Open3.capture3(cmd)

  unless stdout.include? "xcode-select version "
    raise "xcode-select is not installed. Please execute the command below to install it.\nxcode-select install"
  end
end

# clone
def clone
  puts "Clone"
  Dir.chdir parentPath
  cmd = "git clone https://github.com/Carthage/Carthage.git"
  stdout, stderr, status = Open3.capture3(cmd)

  unless isCloned(status) || wasCloned(stderr)
    raise "Failed to clone."
  end
end

def isCloned(status)
  status == 0
end

def wasCloned(stderr)
  filesToPath = ["Source/Carthage/Project.swift"]
  stderr.include?(carthageExistsError) && File.file?(projectFilePath)
end

def carthageExistsError
  "fatal: destination path 'Carthage' already exists and is not an empty directory."
end

# checkout
def checkout
  puts "Checkout"
  Dir.chdir carthagePath
  cmd = "git checkout tags/" + carthageTag
  stdout, stderr, status = Open3.capture3(cmd)
  isCheckouted = status == 0

  unless isCheckouted
    raise "Failed to checkout tags/" + carthageTag
  end
end

# patch
def patch
  puts "Patch"
  #raise "Failed to patch."
  path = projectFilePath
  code = File.read(path)
  result = replacements.inject(code) { |result, xs| result.gsub(xs[0], xs[1]) }
  result = result + flattenStrategyExtension
  File.write(path, result)
end

def parentPath
  Pathname(__dir__).parent.to_s
end

def carthagePath
  parentPath + "/Carthage/"
end

def projectFilePath
  carthagePath + "Source/CarthageKit/Project.swift"
end

def source
  "			.flatMap(.concat) { dependency, version -> SignalProducer<((Dependency, PinnedVersion), Set<Dependency>, Bool?), CarthageError> in
  			.flatMap(.concat) { dependency, version -> BuildSchemeProducer in
				let dependencyPath = self.directoryURL.appendingPathComponent(dependency.relativePath, isDirectory: true).path
				if !FileManager.default.fileExists(atPath: dependencyPath) {
					return .empty
				}
"
end

def flattenStrategyExtension
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
        [".flatMap(.concat) { dependency, version -> BuildSchemeProducer",
         ".flatMap(.maxConcurrent) { dependency, version -> BuildSchemeProducer"],
        [".flatMap(.concat) { dependency, version -> SignalProducer",
	     ".flatMap(.maxConcurrent) { dependency, version -> SignalProducer"],
        [flattenStrategyExtension, ""]
      ]
end

def carthageTag
  `git tag --sort=committerdate | tail -1` 
end

# install
def install
  puts "Build & Install"
  Dir.chdir carthagePath
  cmd = "make install"
  system cmd
end

# main
def main
  begin
    checkXcodeCommandLineTools
    clone
    checkout
    patch
    install
  rescue Exception => e
    puts e
  end
end

main
