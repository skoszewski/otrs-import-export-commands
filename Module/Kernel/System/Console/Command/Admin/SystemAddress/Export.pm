# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::SystemAddress::Export;

use strict;
use warnings;

use base qw(Kernel::System::Console::ExportCommand);

our @ObjectDependencies = (
    'Kernel::System::SystemAddress',
    'Kernel::System::Queue',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ColumnNames} = [
        "Name",
        "Realname",
        "Queue",
        "Comment",
        "Valid",
    ];

    $Self->{ObjectClass} = 'Kernel::System::SystemAddress';

    $Self->SUPER::Configure();

    return;
}

sub ObjectList {
    my ( $Self ) = @_;

    return $Self->{DataObject}->SystemAddressList();
};

sub ObjectGet {
    my ( $Self, %Param ) = @_;

    my %Object = $Self->{DataObject}->SystemAddressGet( %Param );

    my $Valid = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( ValidID => $Object{ValidID} ) || "valid";

    my $Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( QueueID => $Object{QueueID} ) || "Raw";

    # return a list reference
    return [
        $Object{Name},
        $Object{Realname},
        $Queue,
        $Object{Comment},
        $Valid,
    ];
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
