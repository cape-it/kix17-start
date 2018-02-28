# --
# Copyright (C) 2006-2018 c.a.p.e. IT GmbH, http://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::MultipleCustomPackages::List;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::KIXUtils',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List all custom packages.');
    return;
}

sub Run {
    my ( $Self, %Param ) = @_;
    $Self->Print(
        "<yellow>NOTE: The following packages are currently registered and should "
            . "appear in Config.pm and apache2-perl-startup.pl:</yellow>\n"
    );

    my $RegisteredPackages
        = $Kernel::OM->Get('Kernel::System::KIXUtils')->GetRegisteredCustomPackages(%Param);
    for my $CurrPrioKey ( sort( keys( %{$RegisteredPackages} ) ) ) {
        print "\n\t " . $CurrPrioKey;
    }
    print "\n\n";

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut
