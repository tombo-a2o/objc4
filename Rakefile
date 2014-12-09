#!/usr/bin/env ruby

require 'xcodeproj'


HEADER_DIR = "include"
OBJC_HEADER_DIR = HEADER_DIR + "/objc"

task "default" => ["header", "obj"]

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
		task "obj" => files.map{|f| f.path.gsub(/\.m+$/, ".o")}
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
INCLUDE = "-I./include -I./include/objc"
COPTS = "-v -fblocks"
CFLAGS="#{INCLUDE} #{COPTS}"

rule ".o" => ".m" do |t|
	sh "#{CC} #{CFLAGS} -c #{t.source}"
end

rule ".o" => ".mm" do |t|
	sh "#{CC} #{CFLAGS} -c #{t.source}"
end

rule ".o" => ".s" do |t|
	sh "#{CC} #{CFLAGS} -c #{t.source}"
end
