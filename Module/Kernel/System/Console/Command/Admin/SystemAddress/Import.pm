# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::SystemAddress::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::ImportCommand);

our @ObjectDependencies = (
    'Kernel::System::Valid',
    'Kernel::System::SystemAddress',
);

=item Configure()

Configure object specific properties.

=cut

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass} = 'Kernel::System::SystemAddress';
    $Self->{CacheType} = 'SystemAddress';

    $Self->SUPER::Configure();

    my %ReversedSystemAddressList = reverse $Self->{DataObject}->SystemAddressList( Valid => 0 );
    $Self->{ObjectList} = \%ReversedSystemAddressList;

    return;
}

=item ObjectProperty()

Resolves object property name from spreadsheet column name and assigns a value.

=cut

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    if ( $ColumnName =~ m/^name$/i ) {          # Name
        return ( 'Name', $ColumnText );
    } elsif ( $ColumnName =~ m/^realname$/i ) {   # Realname
        return ( 'Realname', $ColumnText );
    } elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText ); 
        return ( 'ValidID', $ValidID || 1 );
    } elsif ( $ColumnName =~ m/^queue$/i ) {    # Queue
        my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $ColumnText );
        return ( 'QueueID', $QueueID || 1 );
    } elsif ( $ColumnName =~ m/^comment$/i ) {  # Comment
        return ( 'Comment', $ColumnText );
    }

    return;
}

=item ObjectAdd()

Adds a new object

=cut

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->SystemAddressAdd( %NewObject );
}

=item ObjectUpdate()

Updates the existing object

=cut

sub ObjectUpdate {
    my ( $Self, %UpdatedObject ) = @_;

    return $Self->{DataObject}->SystemAddressUpdate( %UpdatedObject );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut