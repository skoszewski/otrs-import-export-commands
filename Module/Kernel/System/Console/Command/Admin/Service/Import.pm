
package Kernel::System::Console::Command::Admin::Service::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::ImportCommand);
use Text::CSV;

our @ObjectDependencies = (
    'Kernel::System::Service',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass} = 'Kernel::System::Service';

    my %ReversedServiceList = reverse $Self->{DataObject}->ServiceList( UserID => 1 );
    $Self->{ObjectList} = \%ReversedServiceList;

    return;
}

=item ObjectProperty()

Resolves object property name from spreadsheet column name and assigns a value.

=cut

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    if ( $ColumnName =~ m/^name$/i ) {          # Name
        # check if the specified Service already exists and if yes skip it
        return if $Self->{ObjectList}->{$ColumnText};

        return ( 'Name', $ColumnText );
    } elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText ); 
        return ( 'ValidID', $ValidID || 1);
    } elsif ( $ColumnName =~ m/^comment$/i ) {  # Comment
        return ( 'Comment', $ColumnText );
    }
}

=item ObjectAdd()

Adds a new object

=cut

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->ServiceAdd( %NewObject );
}

1;
