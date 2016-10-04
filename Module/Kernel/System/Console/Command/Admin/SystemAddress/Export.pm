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
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ColumnNames} = [
        "Name",
        "Valid",
        "Comment",
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

    # return a list reference
    return [
        $Object{Name},
        $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( ValidID => $Object{ValidID} ),
        $Object{Comment},
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
