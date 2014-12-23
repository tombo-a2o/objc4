#!/usr/bin/env ruby

require 'xcodeproj'


HEADER_DIR = "include"
OBJC_HEADER_DIR = HEADER_DIR + "/objc"
LLVMLINK="/Users/fchiba/emsdk/clang/e1.27.0_64bit/llvm-link"

task "default" => ["header", "objc4.bc"]

project = Xcodeproj::Project.open("objc.xcodeproj")
target = project.targets.select{|t| t.name == "objc"}.first
objc_headers = nil
target.build_phases.each{ |phase|
	if phase.isa == "PBXHeadersBuildPhase"
		files = phase.files_references
		files.each{ |file|
#			p file
		}
		objc_headers = files.map{|f| f.path}
	elsif phase.isa == "PBXSourcesBuildPhase"
		files = phase.files_references
		files.each{ |file|
#			p file
		}
		files = files.map{|f| f.path}.select{|f| f.match(/\.m+$/) && !f.match(/trampolines/)}
		files = files.map{|f| f.gsub(/\.m+$/, ".o")}
		files <<  "runtime/message.o"
		file "objc4.bc" => files do |t|
			sh "#{LLVMLINK} -o objc4.bc #{t.prerequisites.join(" ")}"
		end
	end
}

other_headers = FileList["*.h"]

directory HEADER_DIR
directory OBJC_HEADER_DIR

task "header" => ["objc_headers", "other_headers"]

task "objc_headers" => objc_headers do |t|
	cp t.prerequisites, OBJC_HEADER_DIR
end

task "other_headers" => other_headers do |t|
	cp t.prerequisites, HEADER_DIR
end


CC = "emcc"
INCLUDE = "-I./include -I./include/objc -I./runtime"
COPTS = "-v -fblocks -fobjc-runtime=macosx"
#COPTS = "-v -fblocks -s LINKABLE=1"
CFLAGS="#{INCLUDE} #{COPTS}"

rule ".o" => ".m" do |t|
	sh "#{CC} #{CFLAGS} -o #{t.name} -c #{t.source}"
end

rule ".o" => ".mm" do |t|
	sh "#{CC} #{CFLAGS} -o #{t.name} -c #{t.source}"
end

rule ".o" => ".s" do |t|
	sh "#{CC} #{CFLAGS} -o #{t.name} -c #{t.source}"
end
