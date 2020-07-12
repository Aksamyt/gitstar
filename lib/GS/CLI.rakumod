unit package GS::CLI;

use GS::Util;

sub git-exists(--> Bool) {
	my $proc = shell <command -v git>, :!in:!out:!err;
	return $proc.exitcode == 0
}

PROCESS::<%SUB-MAIN-OPTS> := {
	:named-anywhere,
};

proto MAIN(|) is export {
	note 'git: Command not found' and exit 127 unless git-exists;
	{*}
}

multi MAIN(
	'init',
	Str $cwd?,
	Bool :interactive(:$i),
	Bool :$create-cwd,
	Bool :$wipe-contents,
	Bool :$ignore-contents,
	Bool :$reinit,
) {
	CATCH {
		when X::IO::Dir {
			note .Str;
			proceed
		}
		when “cwd doesn’t exist” {
			note "$*CWD: No such file or directory";
			if $create-cwd or $i and (lc prompt 'Create path? [y/N] ') eq 'y' {
				mkdir $*CWD;
				.resume
			}
			proceed
		}
		when “cwd not empty” {
			note "$*CWD: Directory not empty";
			if $wipe-contents or $i and (lc prompt 'Wipe contents? [wipe/N] ') eq 'wipe' {
				$*CWD.&GS::Util::clean-dir;
				.resume
			}
			if $ignore-contents or $i and (lc prompt 'Ignore contents? [y/N] ') eq 'y' {
				.resume
			}
			proceed
		}
		when “git exists” {
			note "$*CWD/.git: Existing Git repository";
			if $reinit or $i and (lc prompt 'Reinit repository? [y/N] ') eq 'y' {
				.resume
			}
			proceed
		}
		note 'Aborting';
		exit 1
	}

	$*CWD = $cwd.IO andthen .=resolve with $cwd;
	die “cwd doesn’t exist” unless $*CWD.e;
	die “cwd not empty” if $*CWD.dir.elems;
	die “git exists” if $*CWD.add('.git').IO.e;
	run <git init>;
}
