
package Kernel::System::Console::Command::Admin::Service::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::ImportCommand);
use Text::CSV;

our @ObjectDependencies = (
    'Kernel::System::Service',
    'Kernel::System::Valid',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass} = 'Kernel::System::Service';
    $Self->{CacheType} = 'Service';
    $Self->{PropertyNames} = [
        "Name",
        "ValidID",
        "Comment",
    ];

    $Self->SUPER::Configure();

    my %ReversedServiceList = reverse $Self->{DataObject}->ServiceList( UserID => 1 );
    $Self->{ObjectList} = \%ReversedServiceList;

    return;
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    return $Self->{DataObject}->ServiceGet(
        ServiceID => $ObjectId,
        UserID => 1,
    );
}

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    if ( $ColumnName =~ m/^name$/i ) {          # Name
        return ( 'Name', $ColumnText );
    } elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText ); 
        return ( 'ValidID', $ValidID || 1);
    } elsif ( $ColumnName =~ m/^comment$/i ) {  # Comment
        return ( 'Comment', $ColumnText || '' );
    }
}

sub SplitServiceName {
    my ( $Self, $FullServiceName ) = @_;

    if ( $FullServiceName =~ m/::/ ) {
        my @Parts = split '::', $FullServiceName;
        my $Service = pop @Parts;
        my $ParentService = join '::', @Parts;
        my $ParentServiceID = $Self->{DataObject}->ServiceLookup( Name => $ParentService );
        if (!$ParentServiceID) {
            $Self->Print("<red>Specified sub-service name '$ParentService' does not exist!</red>.\n");
            return (undef, undef);
        }

        return ( $ParentServiceID, $Service );
    } else {
        return ( 0, $FullServiceName );
    }
}

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    my ( $ParentID, $Name ) = $Self->SplitServiceName( $NewObject{Name} );

    # Check if service name is correct
    return if !$Name;
    
    # Modify NewObject properites
    $NewObject{ParentID} = $ParentID;
    $NewObject{Name} = $Name;

    # Add service
    return $Self->{DataObject}->ServiceAdd( %NewObject );
}

sub ObjectUpdate {
    my ( $Self, %NewObject ) = @_;

    my ( $ParentID, $Name ) = $Self->SplitServiceName( $NewObject{Name} );

    # Check if service name is correct
    return if !$Name;
    
    # Modify NewObject properites
    $NewObject{ParentID} = $ParentID;
    $NewObject{Name} = $Name;

    return $Self->{DataObject}->ServiceUpdate( %NewObject );
}

1;
