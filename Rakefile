require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

X12_VERSION = "0.1.0"

begin
  require "rubygems"
rescue LoadError
  nil
end

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/*_test.rb" ]
  test.verbose = true
end

spec = Gem::Specification.new do |spec|
  spec.name = "x12"
  spec.version = X12_VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = "A generalized Ruby EDI x12 parsing engine."
  spec.files =  Dir.glob("{cf,examples,lib,test,bin,util/bench}/**/**/*") +
                      ["Rakefile"]
  spec.require_path = "lib"
  
  spec.test_files = Dir[ "test/*_test.rb" ]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README LICENSE AUTHORS TODO}
  spec.rdoc_options << '--title' << 'x12 Documentation' <<
                       '--main'  << 'README' << '-q'
  spec.author = "Chris Parker"
  spec.email = "chris.p@adelpo.com, mrcsparker@gmail.com"
  spec.rubyforge_project = "x12-parser"
  spec.homepage = "http://rubyforge.org/projects/x12-parser/"
  spec.description = <<END_DESC
  EDI x12 is a standard format for parsing and reading
  Invoices, Orders, etc.  This library makes that easier.
END_DESC
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README",
                           #"CHANGELOG",
                           "AUTHORS", "COPYING",
                           "LICENSE", "lib/" )
  rdoc.main     = "README"
  rdoc.rdoc_dir = "doc/html"
  rdoc.title    = "x12 Documentation"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :build_archives => [:package,:rcov,:rdoc] do
  mv "pkg/x12-#{x12_VERSION}.tgz", "pkg/x12-#{x12_VERSION}.tar.gz"
  sh "tar cjvf pkg/x12_coverage-#{x12_VERSION}.tar.bz2 coverage"
  sh "tar cjvf pkg/x12_doc-#{x12_VERSION}.tar.bz2 doc/html"
  cd "pkg"
  sh "tar cjvf x12-#{X12_VERSION}.tar.bz2 x12-#{x12_VERSION}"
end

task :run_benchmarks do
  files = FileList["util/bench/**/**/*.rb"]
  files.sort!
  files.uniq!
  names = files.map { |r| r.sub("util/bench","").split("/").map { |e| e.capitalize } }
  names.map! { |e| e[1..-2].join("::") + " <BENCH: #{e[-1].sub('Bench_','').sub('.rb','')}>" }
  start_time = Time.now
  files.zip(names).each { |f,n|
    puts "\n#{n}\n\n"
    sh "ruby -Ilib #{f}"
    puts "\n"
  }
  end_time = Time.now
  puts "\n** Total Run Time:  #{end_time-start_time}s **"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir[ "test/*_test.rb" ]
  end
rescue LoadError
  nil
end
