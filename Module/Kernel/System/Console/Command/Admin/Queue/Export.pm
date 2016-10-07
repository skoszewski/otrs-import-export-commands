# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Queue::Export;

use strict;
use warnings;

use base qw(Kernel::System::Console::ExportCommand);

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

    $Self->{ColumnNames} = [
        "Name",
        "Valid",
        "Group",
        "Calendar",
        "First Response Time",
        "First Response Notify",
        "Update Time",
        "Update Notify",
        "Solution Time",
        "Solution Notify",
        "Unlock Timeout",
        "Follow Up",
        "Follow Up Lock",
        "Default Sign Key",
        "System Address",
        "Salutation",
        "Signature",
        "Comment",
    ];

    $Self->{ObjectClass} = 'Kernel::System::Queue';

    $Self->SUPER::Configure();

    # create a hash with follow-up option names
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name FROM follow_up_possible',
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->{FollowUpOptionsList}->{ $Row[0] } = $Row[1];
    }

    return;
}

sub ObjectList {
    my ($Self) = @_;

    return $Self->{DataObject}->QueueList();
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    my %Object = $Self->{DataObject}->QueueGet( ID => $ObjectId );

    my $Group = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup( GroupID => $Object{GroupID} );

    my %SystemAddressInfo = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressGet(
        ID => $Object{SystemAddressID}
    );

    my %SalutationInfo = $Kernel::OM->Get('Kernel::System::Salutation')->SalutationGet(
        ID => $Object{SalutationID}
    );

    my %SignatureInfo = $Kernel::OM->Get('Kernel::System::Signature')->SignatureGet(
        ID => $Object{SignatureID}
    );

    my $FollowUpId = $Self->{FollowUpOptionsList}->{ $Object{FollowUpID} };

    # return a list reference
    return [
        $Object{Name},
        $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( ValidID => $Object{ValidID} ),
        $Group,
        $Object{Calendar},
        $Object{FirstResponseTime},
        $Object{FirstResponseNotify},
        $Object{UpdateTime},
        $Object{UpdateNotify},
        $Object{SolutionTime},
        $Object{SolutionNotify},
        $Object{UnlockTimeout},
        $FollowUpId,
        $Object{FollowUpLock} ? 'yes' : 'no',
        $Object{DefaultSignKey},
        $SystemAddressInfo{Name},
        $SalutationInfo{Name},
        $SignatureInfo{Name},
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
