#!/usr/bin/perl

# test.pl
# Run unit tests.

use strict;
use File::Basename;

chdir dirname $0;
chomp (my $DIR = `pwd`);

my $TESTLIBNAME = "libobjc.A.dylib";
my $TESTLIBPATH = "/usr/lib/$TESTLIBNAME";

my $BUILDDIR = "/tmp/test-$TESTLIBNAME-build";

# xterm colors
my $red = "\e[41;37m";
my $yellow = "\e[43;37m";
my $def = "\e[0m";

# clean, help
if (scalar(@ARGV) == 1) {
    my $arg = $ARGV[0];
    if ($arg eq "clean") {
        my $cmd = "rm -rf $BUILDDIR *~";
        print "$cmd\n";
        `$cmd`;
        exit 0;
    }
    elsif ($arg eq "-h" || $arg eq "-H" || $arg eq "-help" || $arg eq "help") {
        print(<<END);
usage: $0 [options] [testname ...]
       $0 clean
       $0 help

testname:
    `testname` runs a specific test. If no testnames are given, runs all tests.

options:
    ROOT=/path/to/project.roots/

    LANGUAGE=c,c++,objective-c,objective-c++,swift
    MEM=mrc,arc,gc
    STDLIB=libc++,libstdc++
    GUARDMALLOC=0|1

    BUILD=0|1
    RUN=0|1
    VERBOSE=0|1

examples:

    test installed library, no gc
    $0

    test buildit-built root, MRC and ARC and GC
    $0 ROOT=/tmp/libclosure.roots MEM=mrc,arc,gc
END
        exit 0;
    }
}

#########################################################################
## Tests

my %ALL_TESTS;

#########################################################################
## Variables for use in complex build and run rules

# variable         # example value

# things you can multiplex on the command line
# LANGUAGE=c,c++,objective-c,objective-c++,swift
# MEM=mrc,arc,gc
# STDLIB=libc++,libstdc++
# GUARDMALLOC=0,1

# things you can set once on the command line
# ROOT=/path/to/project.roots
# BUILD=0|1
# RUN=0|1
# VERBOSE=0|1



my $BUILD;
my $RUN;
my $VERBOSE;

my $crashcatch = <<'END';
// interpose-able code to catch crashes, print, and exit cleanly
#include <signal.h>
#include <string.h>
#include <unistd.h>

// from dyld-interposing.h
#define DYLD_INTERPOSE(_replacement,_replacee) __attribute__((used)) static struct{ const void* replacement; const void* replacee; } _interpose_##_replacee __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };

static void catchcrash(int sig)
{
    const char *msg;
    switch (sig) {
    case SIGILL:  msg = "CRASHED: SIGILL\\n";  break;
    case SIGBUS:  msg = "CRASHED: SIGBUS\\n";  break;
    case SIGSYS:  msg = "CRASHED: SIGSYS\\n";  break;
    case SIGSEGV: msg = "CRASHED: SIGSEGV\\n"; break;
    case SIGTRAP: msg = "CRASHED: SIGTRAP\\n"; break;
    case SIGABRT: msg = "CRASHED: SIGABRT\\n"; break;
    default: msg = "SIG\?\?\?\?\\n"; break;
    }
    write(STDERR_FILENO, msg, strlen(msg));
    _exit(0);
}

static void setupcrash(void) __attribute__((constructor));
static void setupcrash(void)
{
    signal(SIGILL, &catchcrash);
    signal(SIGBUS, &catchcrash);
    signal(SIGSYS, &catchcrash);
    signal(SIGSEGV, &catchcrash);
    signal(SIGTRAP, &catchcrash);
    signal(SIGABRT, &catchcrash);
}


static int hacked = 0;
ssize_t hacked_write(int fildes, const void *buf, size_t nbyte)
{
    if (!hacked) {
        setupcrash();
        hacked = 1;
    }
    return write(fildes, buf, nbyte);
}

DYLD_INTERPOSE(hacked_write, write);

END


#########################################################################
## Harness


# map language to buildable extensions for that language
my %extensions_for_language = (
    "c"     => ["c"],
    "objective-c" => ["c", "m"],
    "c++" => ["c", "cc", "cp", "cpp", "cxx", "c++"],
    "objective-c++" => ["c", "m", "cc", "cp", "cpp", "cxx", "c++", "mm"],
    "swift" => ["swift"],

    "any" => ["c", "m", "cc", "cp", "cpp", "cxx", "c++", "mm", "swift"],
    );

# map extension to languages
my %languages_for_extension = (
    "c" => ["c", "objective-c", "c++", "objective-c++"],
    "m" => ["objective-c", "objective-c++"],
    "mm" => ["objective-c++"],
    "cc" => ["c++", "objective-c++"],
    "cp" => ["c++", "objective-c++"],
    "cpp" => ["c++", "objective-c++"],
    "cxx" => ["c++", "objective-c++"],
    "c++" => ["c++", "objective-c++"],
    "swift" => ["swift"],
    );

# Run some newline-separated commands like `make` would, stopping if any fail
# run("cmd1 \n cmd2 \n cmd3")
sub make {
    my $output = "";
    my @cmds = split("\n", $_[0]);
    die if scalar(@cmds) == 0;
    $? = 0;
    foreach my $cmd (@cmds) {
        chomp $cmd;
        next if $cmd =~ /^\s*$/;
        $cmd .= " 2>&1";
        print "$cmd\n" if $VERBOSE;
        $output .= `$cmd`;
        last if $?;
    }
    print "$output\n" if $VERBOSE;
    return $output;
}

sub chdir_verbose {
    my $dir = shift;
    chdir $dir || die;
    print "cd $dir\n" if $VERBOSE;
}


# Return test names from the command line.
# Returns all tests if no tests were named.
sub gettests {
    my @tests;

    foreach my $arg (@ARGV) {
        push @tests, $arg  if ($arg !~ /=/  &&  $arg !~ /^-/);
    }

    opendir(my $dir, $DIR) || die;
    while (my $file = readdir($dir)) {
        my ($name, $ext) = ($file =~ /^([^.]+)\.([^.]+)$/);
        next if ! $languages_for_extension{$ext};

        open(my $in, "< $file") || die "$file";
        my $contents = join "", <$in>;
        if (defined $ALL_TESTS{$name}) {
            print "${yellow}SKIP: multiple tests named '$name'; skipping file '$file'.${def}\n";
        } else {
            $ALL_TESTS{$name} = $ext  if ($contents =~ m#^[/*\s]*TEST_#m);
        }
        close($in);
    }
    closedir($dir);

    if (scalar(@tests) == 0) {
        @tests = keys %ALL_TESTS;
    }

    @tests = sort @tests;

    return @tests;
}


# print text with a colored prefix on each line
sub colorprint {
    my $color = shift;
    while (my @lines = split("\n", shift)) {
        for my $line (@lines) {
            chomp $line;
            print "$color $def$line\n";
        }
    }
}

sub rewind {
    seek($_[0], 0, 0);
}

# parse name=value,value pairs
sub readconditions {
    my ($conditionstring) = @_;

    my %results;
    my @conditions = ($conditionstring =~ /\w+=(?:[^\s,]+,?)+/g);
    for my $condition (@conditions) {
        my ($name, $values) = ($condition =~ /(\w+)=(.+)/);
        $results{$name} = [split ',', $values];
    }

    return %results;
}

sub check_output {
    my %C = %{shift()};
    my $name = shift;
    my @output = @_;

    my %T = %{$C{"TEST_$name"}};

    # node.js emits an extra newline
    pop @output;

    # Quietly strip MallocScribble before saving the "original" output
    # because it is distracting.
    filter_malloc(\@output);

    my @original_output = @output;

    # Run result-checking passes, reducing @output each time
    my $xit = 1;
    my $bad = "";
    my $warn = "";
    my $runerror = $T{TEST_RUN_OUTPUT};
    filter_hax(\@output);
    filter_verbose(\@output);
    $warn = filter_warn(\@output);
    $bad |= filter_guardmalloc(\@output) if ($C{GUARDMALLOC});
    $bad |= filter_valgrind(\@output) if ($C{VALGRIND});
    $bad = filter_expected(\@output, \%C, $name) if ($bad eq "");
    $bad = filter_bad(\@output)  if ($bad eq "");

    # OK line should be the only one left
    $bad = "(output not 'OK: $name')" if ($bad eq ""  &&  (scalar(@output) != 1  ||  $output[0] !~ /^OK: $name/));

    if ($bad ne "") {
        print "${red}FAIL: /// test '$name' \\\\\\$def\n";
        colorprint($red, @original_output);
        print "${red}FAIL: \\\\\\ test '$name' ///$def\n";
        print "${red}FAIL: $name: $bad$def\n";
        $xit = 0;
    }
    elsif ($warn ne "") {
        print "${yellow}PASS: /// test '$name' \\\\\\$def\n";
        colorprint($yellow, @original_output);
        print "${yellow}PASS: \\\\\\ test '$name' ///$def\n";
        print "PASS: $name (with warnings)\n";
    }
    else {
        print "PASS: $name\n";
    }
    return $xit;
}

sub filter_expected
{
    my $outputref = shift;
    my %C = %{shift()};
    my $name = shift;

    my %T = %{$C{"TEST_$name"}};
    my $runerror = $T{TEST_RUN_OUTPUT}  ||  return "";

    my $bad = "";

    my $output = join("\n", @$outputref) . "\n";
    if ($output !~ /$runerror/) {
	$bad = "(run output does not match TEST_RUN_OUTPUT)";
	@$outputref = ("FAIL: $name");
    } else {
	@$outputref = ("OK: $name");  # pacify later filter
    }

    return $bad;
}

sub filter_bad
{
    my $outputref = shift;
    my $bad = "";

    my @new_output;
    for my $line (@$outputref) {
	if ($line =~ /^BAD: (.*)/) {
	    $bad = "(failed)";
	} else {
	    push @new_output, $line;
	}
    }

    @$outputref = @new_output;
    return $bad;
}

sub filter_warn
{
    my $outputref = shift;
    my $warn = "";

    my @new_output;
    for my $line (@$outputref) {
	if ($line !~ /^WARN: (.*)/) {
	    push @new_output, $line;
        } else {
	    $warn = "(warned)";
	}
    }

    @$outputref = @new_output;
    return $warn;
}

sub filter_verbose
{
    my $outputref = shift;

    my @new_output;
    for my $line (@$outputref) {
	if ($line !~ /^VERBOSE: (.*)/) {
	    push @new_output, $line;
	}
    }

    @$outputref = @new_output;
}

sub filter_hax
{
    my $outputref = shift;

    my @new_output;
    for my $line (@$outputref) {
	if ($line !~ /Class OS_tcp_/) {
	    push @new_output, $line;
	}
    }

    @$outputref = @new_output;
}

sub filter_valgrind
{
    my $outputref = shift;
    my $errors = 0;
    my $leaks = 0;

    my @new_output;
    for my $line (@$outputref) {
	if ($line =~ /^Approx: do_origins_Dirty\([RW]\): missed \d bytes$/) {
	    # --track-origins warning (harmless)
	    next;
	}
	if ($line =~ /^UNKNOWN __disable_threadsignal is unsupported. This warning will not be repeated.$/) {
	    # signals unsupported (harmless)
	    next;
	}
	if ($line =~ /^UNKNOWN __pthread_sigmask is unsupported. This warning will not be repeated.$/) {
	    # signals unsupported (harmless)
	    next;
	}
	if ($line !~ /^^\.*==\d+==/) {
	    # not valgrind output
	    push @new_output, $line;
	    next;
	}

	my ($errcount) = ($line =~ /==\d+== ERROR SUMMARY: (\d+) errors/);
	if (defined $errcount  &&  $errcount > 0) {
	    $errors = 1;
	}

	(my $leakcount) = ($line =~ /==\d+==\s+(?:definitely|possibly) lost:\s+([0-9,]+)/);
	if (defined $leakcount  &&  $leakcount > 0) {
	    $leaks = 1;
	}
    }

    @$outputref = @new_output;

    my $bad = "";
    $bad .= "(valgrind errors)" if ($errors);
    $bad .= "(valgrind leaks)" if ($leaks);
    return $bad;
}



sub filter_malloc
{
    my $outputref = shift;
    my $errors = 0;

    my @new_output;
    my $count = 0;
    for my $line (@$outputref) {
        # Ignore MallocScribble prologue.
        # Ignore MallocStackLogging prologue.
        if ($line =~ /malloc: enabling scribbling to detect mods to free/  ||
            $line =~ /Deleted objects will be dirtied by the collector/  ||
            $line =~ /malloc: stack logs being written into/  ||
            $line =~ /malloc: recording malloc and VM allocation stacks/)
        {
            next;
	}

        # not malloc output
        push @new_output, $line;

    }

    @$outputref = @new_output;
}

sub filter_guardmalloc
{
    my $outputref = shift;
    my $errors = 0;

    my @new_output;
    my $count = 0;
    for my $line (@$outputref) {
	if ($line !~ /^GuardMalloc\[[^\]]+\]: /) {
	    # not guardmalloc output
	    push @new_output, $line;
	    next;
	}

        # Ignore 4 lines of guardmalloc prologue.
        # Anything further is a guardmalloc error.
        if (++$count > 4) {
            $errors = 1;
        }
    }

    @$outputref = @new_output;

    my $bad = "";
    $bad .= "(guardmalloc errors)" if ($errors);
    return $bad;
}

sub filter_emcc_warning
{
    my $outputref = shift;
    my $warn = "";

    my @new_output;
    my @lines = split /\n/, $$outputref;
    for my $line (@lines) {
        if ($line !~ /^.*warning:.*/) {
            push @new_output, $line;
        } else {
            $warn = "(warned)";
        }
    }

    $$outputref = join "\n", @new_output;
    return $warn;
}

sub filter_emcc_note
{
    my $outputref = shift;

    my @new_output;
    my @lines = split /\n/, $$outputref;
    for my $line (@lines) {
        if ($line !~ /^.*note:.*/) {
            push @new_output, $line;
        }
    }
    $$outputref = join "\n", @new_output;
}

sub filter_emcc_framework
{
    my $outputref = shift;
    my $warn = "";

    my @new_output;
    my @lines = split /\n/, $$outputref;
    for my $line (@lines) {
        if ($line !~ m{/.*frameworks/CoreFoundation\.framework/CoreFoundation} &&
            $line !~ m{/.*frameworks/Foundation\.framework/Foundation}) {
            push @new_output, $line;
        }
    }

    $$outputref = join "\n", @new_output;
}
# TEST_SOMETHING
# text
# text
# END
sub extract_multiline {
    my ($flag, $contents, $name) = @_;
    if ($contents =~ /$flag\n/) {
        my ($output) = ($contents =~ /$flag\n(.*?\n)END[ *\/]*\n/s);
        die "$name used $flag without END\n"  if !defined($output);
        return $output;
    }
    return undef;
}


# TEST_SOMETHING
# text
# OR
# text
# END
sub extract_multiple_multiline {
    my ($flag, $contents, $name) = @_;
    if ($contents =~ /$flag\n/) {
        my ($output) = ($contents =~ /$flag\n(.*?\n)END[ *\/]*\n/s);
        die "$name used $flag without END\n"  if !defined($output);

        $output =~ s/\nOR\n/\n|/sg;
        $output = "^(" . $output . ")\$";
        return $output;
    }
    return undef;
}


sub gather_simple {
    my $CREF = shift;
    my %C = %{$CREF};
    my $name = shift;
    chdir_verbose $DIR;

    my $ext = $ALL_TESTS{$name};
    my $file = "$name.$ext";
    return 0 if !$file;

    # search file for 'TEST_CONFIG' or '#include "test.h"'
    # also collect other values:
    # TEST_CONFIG test conditions
    # TEST_ENV environment prefix
    # TEST_CFLAGS compile flags
    # TEST_BUILD build instructions
    # TEST_BUILD_OUTPUT expected build stdout/stderr
    # TEST_RUN_OUTPUT expected run stdout/stderr
    open(my $in, "< $file") || die;
    my $contents = join "", <$in>;

    my $test_h = ($contents =~ /^\s*#\s*(include|import)\s*"test\.h"/m);
    my $disabled = ($contents =~ /\bTEST_DISABLED\b/m);
    my $crashes = ($contents =~ /\bTEST_CRASHES\b/m);
    my ($conditionstring) = ($contents =~ /\bTEST_CONFIG\b(.*)$/m);
    my ($envstring) = ($contents =~ /\bTEST_ENV\b(.*)$/m);
    my ($cflags) = ($contents =~ /\bTEST_CFLAGS\b(.*)$/m);
    my ($buildcmd) = extract_multiline("TEST_BUILD", $contents, $name);
    my ($builderror) = extract_multiple_multiline("TEST_BUILD_OUTPUT", $contents, $name);
    my ($runerror) = extract_multiple_multiline("TEST_RUN_OUTPUT", $contents, $name);

    return 0 if !$test_h && !$disabled && !$crashes && !defined($conditionstring) && !defined($envstring) && !defined($cflags) && !defined($buildcmd) && !defined($builderror) && !defined($runerror);

    if ($disabled) {
        print "${yellow}SKIP: $name    (disabled by TEST_DISABLED)$def\n";
        return 0;
    }

    # check test conditions

    my $run = 1;
    my %conditions = readconditions($conditionstring);
    if (! $conditions{LANGUAGE}) {
        # implicit language restriction from file extension
        $conditions{LANGUAGE} = $languages_for_extension{$ext};
    }
    for my $condkey (keys %conditions) {
        my @condvalues = @{$conditions{$condkey}};

        # special case: RUN=0 does not affect build
        if ($condkey eq "RUN"  &&  @condvalues == 1  &&  $condvalues[0] == 0) {
            $run = 0;
            next;
        }

        my $testvalue = $C{$condkey};
        next if !defined($testvalue);
        # testvalue is the configuration being run now
        # condvalues are the allowed values for this test

        my $ok = 0;
        for my $condvalue (@condvalues) {

            # special case: objc and objc++
            if ($condkey eq "LANGUAGE") {
                $condvalue = "objective-c" if $condvalue eq "objc";
                $condvalue = "objective-c++" if $condvalue eq "objc++";
            }

            $ok = 1  if ($testvalue eq $condvalue);

            # special case: SDK allows prefixes
            if ($condkey eq "SDK") {
                $ok = 1  if ($testvalue =~ /^$condvalue/);
            }

            # special case: CC and CXX allow substring matches
            if ($condkey eq "CC"  ||  $condkey eq "CXX") {
                $ok = 1  if ($testvalue =~ /$condvalue/);
            }

            last if $ok;
        }

        # emscripten does not support signals for now
        $ok = 0 if $crashes;

        if (!$ok) {
            my $plural = (@condvalues > 1) ? "one of: " : "";
            print "SKIP: $name    ($condkey=$testvalue, but test requires $plural", join(' ', @condvalues), ")\n";
            return 0;
        }
    }

    # save some results for build and run phases
    $$CREF{"TEST_$name"} = {
        TEST_BUILD => $buildcmd,
        TEST_BUILD_OUTPUT => $builderror,
        TEST_CRASHES => $crashes,
        TEST_RUN_OUTPUT => $runerror,
        TEST_CFLAGS => $cflags,
        TEST_ENV => $envstring,
        TEST_RUN => $run,
    };

    return 1;
}

# Builds a simple test
sub build_simple {
    my %C = %{shift()};
    my $name = shift;
    my %T = %{$C{"TEST_$name"}};
    chdir_verbose "$C{DIR}/$name.build";

    my $ext = $ALL_TESTS{$name};
    my $file = "$DIR/$name.$ext";

    if ($T{TEST_CRASHES}) {
        die "test with test_cashes reached to build phase";
    }

    my $out_ext = "js";
    my $cmd = $T{TEST_BUILD} ? eval "return \"$T{TEST_BUILD}\"" : "$C{COMPILE}   $T{TEST_CFLAGS} $file -o $name.$out_ext";

    # FIXME: emcc sometimes unexpectedly dies with segv, and this is a monkey patch for that
    my $output;
    do {
        if (defined($output)) {
            print "retrying the build..";
        }
        $output = make($cmd);
    } until ($output !~ /Stack dump/);

    filter_emcc_warning(\$output);
    filter_emcc_note(\$output);
    filter_emcc_framework(\$output);

    # rdar://10163155
    $output =~ s/ld: warning: could not create compact unwind for [^\n]+: does not use standard frame\n//g;

    my $ok;
    if (my $builderror = $T{TEST_BUILD_OUTPUT}) {
        # check for expected output and ignore $?
        $ok = 1;                # FIXME
    } elsif ($?) {
        print "${red}FAIL: /// test '$name' \\\\\\$def\n";
        colorprint $red, $output;
        print "${red}FAIL: \\\\\\ test '$name' ///$def\n";
        print "${red}FAIL: $name (build failed)$def\n";
        $ok = 0;
    } elsif ($output ne "") {
        print "${red}FAIL: /// test '$name' \\\\\\$def\n";
        colorprint $red, $output;
        print "${red}FAIL: \\\\\\ test '$name' ///$def\n";
        print "${red}FAIL: $name (unexpected build output)$def\n";
        $ok = 0;
    } else {
        $ok = 1;
    }

    return $ok;
}

# Run a simple test (testname.out, with error checking of stdout and stderr)
sub run_simple {
    my %C = %{shift()};
    my $name = shift;
    my %T = %{$C{"TEST_$name"}};

    if (! $T{TEST_RUN}) {
        print "PASS: $name (build only)\n";
        return 1;
    }
    else {
        chdir_verbose "$C{DIR}/$name.build";
    }

    my $env = "$C{ENV} $T{TEST_ENV}";

    my $cmd = "env $env node ./$name.js";
    my $output = make("sh -c '$cmd 2>&1' 2>&1");
    # need extra sh level to capture "sh: Illegal instruction" after crash
    # fixme fail if $? except tests that expect to crash

    return check_output(\%C, $name, split("\n", $output));
}


sub find_compiler {
    my $result = `which emcc`;
    chomp $result;
    return $result;
}

sub make_one_config {
    my $configref = shift;
    my $root = shift;
    my %C = %{$configref};

    # Aliases
    $C{LANGUAGE} = "objective-c"  if $C{LANGUAGE} eq "objc";
    $C{LANGUAGE} = "objective-c++"  if $C{LANGUAGE} eq "objc++";

    # set the config name now, after massaging the language and sdk,
    # but before adding other settings
    my $configname = config_name(%C);
    die if ($configname =~ /'/);
    die if ($configname =~ / /);
    ($C{NAME} = $configname) =~ s/~/ /g;
    (my $configdir = $configname) =~ s#/##g;
    $C{DIR} = "$BUILDDIR/$configdir";

    # Look up compilers
    $C{CC} = find_compiler;
    $C{CXX} = find_compiler
    $C{SWIFT} = find_compiler

    # Populate cflags
    my $cflags = "--valid-abspath $DIR/../include -I $DIR/../include -fblocks -fobjc-runtime=macosx -s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 ";
    my $objcflags = "$DIR/../libobjc4.a $DIR/../lib/libclosure-65/libclosure.a -D'__weak=__attribute__((objc_gc(weak)))' -D'__strong='";
    my $swiftflags = "-g ";

    # Populate ENV_PREFIX
    $C{ENV} = "LANG=C MallocScribble=1";
    $C{ENV} .= " VERBOSE=1"  if $VERBOSE;
    if ($C{GUARDMALLOC}) {
        $ENV{GUARDMALLOC} = "1";  # checked by tests and errcheck.pl
        $C{ENV} .= " DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib";
    }

    # Populate compiler commands
    $C{COMPILE_C}   = "env LANG=C '$C{CC}'  $cflags -x c -std=gnu99";
    $C{COMPILE_CXX} = "env LANG=C '$C{CXX}' $cflags -x c++";
    $C{COMPILE_M}   = "env LANG=C '$C{CC}'  $cflags $objcflags -x objective-c -std=gnu99";
    $C{COMPILE_MM}  = "env LANG=C '$C{CXX}' $cflags $objcflags -x objective-c++";
    $C{COMPILE_SWIFT} = "env LANG=C '$C{SWIFT}' $swiftflags";

    $C{COMPILE} = $C{COMPILE_C}      if $C{LANGUAGE} eq "c";
    $C{COMPILE} = $C{COMPILE_CXX}    if $C{LANGUAGE} eq "c++";
    $C{COMPILE} = $C{COMPILE_M}      if $C{LANGUAGE} eq "objective-c";
    $C{COMPILE} = $C{COMPILE_MM}     if $C{LANGUAGE} eq "objective-c++";
    $C{COMPILE} = $C{COMPILE_SWIFT}  if $C{LANGUAGE} eq "swift";
    die "unknown language '$C{LANGUAGE}'\n" if !defined $C{COMPILE};

    ($C{COMPILE_NOMEM} = $C{COMPILE}) =~ s/ -fobjc-(?:gc|arc)\S*//g;
    ($C{COMPILE_NOLINK} = $C{COMPILE}) =~ s/ '?-(?:Wl,|l)\S*//g;
    ($C{COMPILE_NOLINK_NOMEM} = $C{COMPILE_NOMEM}) =~ s/ '?-(?:Wl,|l)\S*//g;


    # Reject some self-inconsistent configurations
    if ($C{MEM} !~ /^(mrc|arc|gc)$/) {
        die "unknown MEM=$C{MEM} (expected one of mrc arc gc)\n";
    }

    %$configref = %C;
}

sub make_configs {
    my ($root, %args) = @_;

    my @results = ({});  # start with one empty config

    for my $key (keys %args) {
        my @newresults;
        my @values = @{$args{$key}};
        for my $configref (@results) {
            my %config = %{$configref};
            for my $value (@values) {
                my %newconfig = %config;
                $newconfig{$key} = $value;
                push @newresults, \%newconfig;
            }
        }
        @results = @newresults;
    }

    my @newresults;
    for my $configref(@results) {
        if (make_one_config($configref, $root)) {
            push @newresults, $configref;
        }
    }

    return @newresults;
}

sub config_name {
    my %config = @_;
    my $name = "";
    for my $key (sort keys %config) {
        $name .= '~'  if $name ne "";
        $name .= "$key=$config{$key}";
    }
    return $name;
}

sub run_one_config {
    my %C = %{shift()};
    my @tests = @_;

    # Build and run
    my $testcount = 0;
    my $failcount = 0;

    my @gathertests;
    foreach my $test (@tests) {
        if ($VERBOSE) {
            print "\nGATHER $test\n";
        }

        if ($ALL_TESTS{$test}) {
            gather_simple(\%C, $test) || next;  # not pass, not fail
            push @gathertests, $test;
        } else {
            die "No test named '$test'\n";
        }
    }

    my @builttests;
    if (!$BUILD) {
        @builttests = @gathertests;
        $testcount = scalar(@gathertests);
    } else {
        my $configdir = $C{DIR};
        print $configdir, "\n"  if $VERBOSE;
        mkdir $configdir  || die;

        foreach my $test (@gathertests) {
            if ($VERBOSE) {
                print "\nBUILD $test\n";
            }
            mkdir "$configdir/$test.build"  || die;

            if ($ALL_TESTS{$test}) {
                $testcount++;
                if (!build_simple(\%C, $test)) {
                    $failcount++;
                } else {
                    push @builttests, $test;
                }
            } else {
                die "No test named '$test'\n";
            }
        }
    }

    if (!$RUN  ||  !scalar(@builttests)) {
        # nothing to do
    }
    else {
        foreach my $test (@builttests) {
            print "\nRUN $test\n"  if ($VERBOSE);

            if ($ALL_TESTS{$test})
            {
                if (!run_simple(\%C, $test)) {
                    $failcount++;
                }
            } else {
                die "No test named '$test'\n";
            }
        }
    }

    return ($testcount, $failcount);
}



# Return value if set by "$argname=value" on the command line
# Return $default if not set.
sub getargs {
    my ($argname, $default) = @_;

    foreach my $arg (@ARGV) {
        my ($value) = ($arg =~ /^$argname=(.+)$/);
        return [split ',', $value] if defined $value;
    }

    return [split ',', $default];
}

# Return 1 or 0 if set by "$argname=1" or "$argname=0" on the
# command line. Return $default if not set.
sub getbools {
    my ($argname, $default) = @_;

    my @values = @{getargs($argname, $default)};
    return [( map { ($_ eq "0") ? 0 : 1 } @values )];
}

sub getarg {
    my ($argname, $default) = @_;
    my @values = @{getargs($argname, $default)};
    die "Only one value allowed for $argname\n"  if @values > 1;
    return $values[0];
}

sub getbool {
    my ($argname, $default) = @_;
    my @values = @{getbools($argname, $default)};
    die "Only one value allowed for $argname\n"  if @values > 1;
    return $values[0];
}


# main
my %args;


$args{ARCH} = ["js"];
$args{SDK} = ["emscripten"];

$args{MEM} = getargs("MEM", "mrc");
$args{LANGUAGE} = [ map { lc($_) } @{getargs("LANGUAGE", "objective-c")} ];
$args{STDLIB} = getargs("STDLIB", "libstdc++");

$args{GUARDMALLOC} = getbools("GUARDMALLOC", 0);

$BUILD = getbool("BUILD", 1);
$RUN = getbool("RUN", 1);
$VERBOSE = getbool("VERBOSE", 0);

my $root = getarg("ROOT", "");
$root =~ s#/*$##;

my @tests = gettests();

print "note: -----\n";
print "note: testing root '$root'\n";

my @configs = make_configs($root, %args);

print "note: -----\n";
print "note: testing ", scalar(@configs), " configurations:\n";
for my $configref (@configs) {
    my $configname = $$configref{NAME};
    print "note: configuration $configname\n";
}

if ($BUILD) {
    `rm -rf '$BUILDDIR'`;
    mkdir "$BUILDDIR" || die;
}

my $failed = 0;

my $testconfigs = @configs;
my $failconfigs = 0;
my $testcount = 0;
my $failcount = 0;
for my $configref (@configs) {
    my $configname = $$configref{NAME};
    print "note: -----\n";
    print "note: \nnote: $configname\nnote: \n";

    (my $t, my $f) = eval { run_one_config($configref, @tests); };
    if ($@) {
        chomp $@;
        print "${red}FAIL: $configname${def}\n";
        print "${red}FAIL: $@${def}\n";
        $failconfigs++;
    } else {
        my $color = ($f ? $red : "");
        print "note:\n";
        print "${color}note: $configname$def\n";
        print "${color}note: $t tests, $f failures$def\n";
        $testcount += $t;
        $failcount += $f;
        $failconfigs++ if ($f);
    }
}

print "note: -----\n";
my $color = ($failconfigs ? $red : "");
print "${color}note: $testconfigs configurations, $failconfigs with failures$def\n";
print "${color}note: $testcount tests, $failcount failures$def\n";

$failed = ($failconfigs ? 1 : 0);

exit ($failed ? 1 : 0);
