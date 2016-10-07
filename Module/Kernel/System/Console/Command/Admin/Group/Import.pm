# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Group::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::ImportCommand);

our @ObjectDependencies = (
    'Kernel::System::Group',
    'Kernel::System::Valid',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass}   = 'Kernel::System::Group';
    $Self->{CacheType}     = 'Group';
    $Self->{PropertyNames} = [
        "Name",
        "ValidID",
        "Comment",
    ];

    $Self->SUPER::Configure();

    my %ReversedGroupList = reverse $Self->{DataObject}->GroupList( Valid => 0 );
    $Self->{ObjectList} = \%ReversedGroupList;

    return;
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    return $Self->{DataObject}->GroupGet(
        ID => $ObjectId
    );
}

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    if ( $ColumnName =~ m/^name$/i ) {    # Name
        return ( 'Name', $ColumnText );
    }
    elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText );
        return ( 'ValidID', $ValidID || 1 );
    }
    elsif ( $ColumnName =~ m/^comment$/i ) {    # Comment
        return ( 'Comment', $ColumnText || '' );
    }

    return;
}

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->GroupAdd(%NewObject);
}

sub ObjectUpdate {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->GroupUpdate(%NewObject);
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
