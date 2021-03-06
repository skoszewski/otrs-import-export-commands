# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Group::Export;

use strict;
use warnings;

use base qw(Kernel::System::Console::ExportCommand);

our @ObjectDependencies = (
    'Kernel::System::Group',
    'Kernel::System::Valid',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ColumnNames} = [
        "Name",
        "Valid",
        "Comment",
    ];

    $Self->{ObjectClass} = 'Kernel::System::Group';

    $Self->SUPER::Configure();

    return;
}

sub ObjectList {
    my ($Self) = @_;

    return $Self->{DataObject}->GroupList();
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    my %Object = $Self->{DataObject}->GroupGet( ID => $ObjectId );

    # return a list reference
    return [
        $Object{Name},
        $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( ValidID => $Object{ValidID} ),
        $Object{Comment},
    ];
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
