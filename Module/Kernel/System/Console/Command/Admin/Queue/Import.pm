# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Queue::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::ImportCommand);

our @ObjectDependencies = (
    'Kernel::System::Queue',
    'Kernel::System::Valid',
    'Kernel::System::Group',
    'Kernel::System::SystemAddress',
    'Kernel::System::Salutation',
    'Kernel::System::Signature',
    'Kernel::System::DB',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass} = 'Kernel::System::Queue';
    $Self->{CacheType} = "Queue";
    $Self->{PropertyNames} = [
        "Name",
        "ValidID",
        "GroupID",
        "Calendar",
        "FirstResponseTime",
        "UpdateTime",
        "SolutionTime",
        "UnlockTimeout",
        "SystemAddressID",
        "SalutationID",
        "SignatureID",
        "FollowUpID",
        "Comment",
    ];

    $Self->{ObjectIdName} = "QueueID";  # Custom ID name

    $Self->SUPER::Configure();

    # create a hash with follow-up option names
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name FROM follow_up_possible',
    );
    
    my %FollowUpOptionsList;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $FollowUpOptionsList{ $Row[0] } = $Row[1];
    }

    my %ReversedFollowUpOptionsList = reverse %FollowUpOptionsList;
    $Self->{FollowUpOptionsList} = \%ReversedFollowUpOptionsList;

    # reversed queue list
    my %ReversedQueueList = reverse $Self->{DataObject}->QueueList( Valid => 0 );
    $Self->{ObjectList} = \%ReversedQueueList;

    return;
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    return $Self->{DataObject}->QueueGet(
        ID => $ObjectId
    );
}

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    # Name, ValidID, GroupID, Calendar, FirstResponseTime, UpdateTime, SolutionTime, UnlockTimeout, SystemAddressID, SalutationID, SignatureID, FollowUpID, Comment

    if ( $ColumnName =~ m/^name$/i ) {                          # Name
        return ( 'Name', $ColumnText );
    } elsif ( $ColumnName =~ m/^valid$/i ) {                    # Valid

        my %ValidList = reverse $Kernel::OM->Get('Kernel::System::Valid')->ValidList(); 
        my $ValidID = $ValidList{$ColumnText};
        if (!$ValidID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid name.</red>\n");
        }
        return ( 'ValidID', $ValidID || 1 );

    } elsif ( $ColumnName =~ m/^group$/i ) {                    # Group

        my %GroupList = reverse $Kernel::OM->Get('Kernel::System::Group')->GroupList();
        my $GroupID = $GroupList{$ColumnText};
        if (!$GroupID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid Group name.</red>\n");
        }
        return ( 'GroupID', $GroupID || 1 );

    } elsif ( $ColumnName =~ m/^calendar$/i ) {                 # Calendar

        return ( 'Calendar', $ColumnText || '' );

    } elsif ( $ColumnName =~ m/^first *response *time$/i ) {    # First Response Time

        return ( 'FirstResponseTime', $ColumnText || '' );

    } elsif ( $ColumnName =~ m/^update *time$/i ) {             # Update Time

        return ( 'UpdateTime', $ColumnText || '' );

    } elsif ( $ColumnName =~ m/^solution *time$/i ) {           # Solution Time

        return ( 'SolutionTime', $ColumnText || '' );

    } elsif ( $ColumnName =~ m/^unlock *timeout$/i ) {          # Unlock Timeout

        return ( 'UnlockTimeout', $ColumnText || '' );

    } elsif ( $ColumnName =~ m/^system *address$/i ) {          # SystemAddress

        my %SystemAddressList = reverse $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressList();
        my $SystemAddressID = $SystemAddressList{$ColumnText};
        if (!$SystemAddressID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid SystemAddress name.</red>\n");
        }
        return ( 'SystemAddressID', $SystemAddressID || 1 );

    } elsif ( $ColumnName =~ m/^salutation$/i ) {               # Salutation

        my %SalutationList = reverse $Kernel::OM->Get('Kernel::System::Salutation')->SalutationList();
        my $SalutationID = $SalutationList{$ColumnText};
        if (!$SalutationID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid Salutation name.</red>\n");
        }
        return ( 'SalutationID', $SalutationID || 1 );

    } elsif ( $ColumnName =~ m/^signature$/i ) {                # Signature

        my %SignatureList = reverse $Kernel::OM->Get('Kernel::System::Signature')->SignatureList();
        my $SignatureID = $SignatureList{$ColumnText};
        if (!$SignatureID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid Signature name.</red>\n");
        }
        return ( 'SignatureID', $SignatureID || 1 );

    } elsif ( $ColumnName =~ m/^follow *up$/i ) {               # Follow Up
        
        my $FollowUpID = $Self->{FollowUpOptionsList}->{ $ColumnText };
        if (!$FollowUpID) {
            $Self->Print("<red>\"$ColumnText\" is not a valid follow up option name.</red>\n");
        }
        return ( 'FollowUpID', $FollowUpID || 1 );

    } elsif ( $ColumnName =~ m/^comment$/i ) {                  # Comment

        return ( 'Comment', $ColumnText || '' );

    } else {
        $Self->Print("<red>Unknown column name found: \"$ColumnName\".</red>\n");
    }

    return;
}

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->QueueAdd( %NewObject );
}

sub ObjectUpdate {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->QueueUpdate( %NewObject );
}

1;

