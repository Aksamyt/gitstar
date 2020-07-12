unit module GS::Util;

our sub clean-dir(IO:D $_, :$unlink-self) {
	my @child = .dir;
	for @child {
		.&clean-dir(:unlink-self) when :d;
		.unlink when :!d;
	}
	.rmdir if $unlink-self;
}
