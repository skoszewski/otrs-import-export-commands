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

use Text::CSV;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Queue',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::System::Group',
    'Kernel::System::SystemAddress',
    'Kernel::System::Salutation',
    'Kernel::System::Signature',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Imports several queues from a CSV file.');

    $Self->AddArgument(
        Name        => 'file',
        Description => "A CSV formatted input file with queue definitions.",
        Required    => 1,
        ValueRegex  => qr/.*\.csv$/smxi,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    # Check if the specified file exists.
    my $FileName = $Self->GetArgument('file');

    if ( ! -e $FileName ) {
        # No? Abort then.
        die "File $FileName not found.\n";
    }

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Starting queues import...</yellow>\n");

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    my $CSV = Text::CSV->new(
        {
            quote_char  => '"',
            sep_char    => ',',
            binary      => 1,
        }
    );

    open my $FileHandle, "<:encoding(utf8)", $Self->GetArgument('file') || return $Self->ExitCodeError();

    # Read header line
    if ( my $HeaderRef = $CSV->getline($FileHandle) ) {

        my %QueueListByName = reverse $QueueObject->QueueList( Valid => 0 );

        QUEUE:
        # Go through the file, reading each queue definition
        while ( my $ColRef = $CSV->getline($FileHandle) ) {
            my @ColumnNames = @{ $HeaderRef };
            my @Columns = @{ $ColRef };
            my ($ColumnName, $ColumnText);
            my %NewQueue = ();

            COLUMN:
            while ( $ColumnName = shift @ColumnNames ) {
                $ColumnText = shift @Columns;

                if ( $ColumnName =~ m/^name$/i ) {          # Name
                    # check if the specified Queue already exists and if yes skip it
                    next QUEUE if $QueueListByName{$ColumnText};

                    $NewQueue{Name} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
                    $NewQueue{Valid} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^group$/i ) {    # Group
                    $NewQueue{Group} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^calendar$/i ) { # Calendar
                    $NewQueue{Calendar} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^first.*response.*time$/i ) {    # First Response Time
                    $NewQueue{FirstResponseTime} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^update.*time$/i ) {     # Update Time
                    $NewQueue{UpdateTime} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^solution.*time$/i ) {   # Solution Time
                    $NewQueue{SolutionTime} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^unlock.*timeout$/i ) {  # Unlock Timeout
                    $NewQueue{UnlockTimeout} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^system.*address.*name$/i ) {  # System Address Name
                    $NewQueue{SystemAddressName} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^salutation$/i ) {       # Salutation
                    $NewQueue{Salutation} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^signature$/i ) {        # Signature
                    $NewQueue{Signature} = $ColumnText;
                    next COLUMN;
                } elsif ( $ColumnName =~ m/^comment$/i ) {          # Comment
                    $NewQueue{Comment} = $ColumnText;
                    next COLUMN;
                }
            }

            # check valid status name
            my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $NewQueue{Valid} ); 
            if ( !$ValidID ) {
                $Self->PrintError("Unknown validity status name found: \"$NewQueue{Valid}\".\n");
                return $Self->ExitCodeError();
            }

            # check group
            my $GroupID = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup( Group => $NewQueue{Group} );
            if ( !$GroupID ) {
                $Self->PrintError("Found no GroupID for $NewQueue{Group}\n");
                return $Self->ExitCodeError();
            }

            my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
            my $SystemAddressID;

            # check System Address
            if ( $NewQueue{SystemAddressName} ) {
                my %SystemAddressList = $SystemAddressObject->SystemAddressList(
                    Valid => 1
                );
                ADDRESS:
                for my $ID ( sort keys %SystemAddressList ) {
                    my %SystemAddressInfo = $SystemAddressObject->SystemAddressGet(
                        ID => $ID
                    );
                    if ( $SystemAddressInfo{Name} eq $NewQueue{SystemAddressName} ) {
                        $SystemAddressID = $ID;
                        last ADDRESS;
                    }
                }
                if ( !$SystemAddressID ) {
                    $Self->PrintError("Address $NewQueue{SystemAddressName} not found\n");
                    return $Self->ExitCodeError();
                }
            }

            # find salutation id
            my %Salutations = $Kernel::OM->Get('Kernel::System::Salutation')->SalutationList();
            my ($SalutationID) = grep { $NewQueue{Salutation} eq $Salutations{$_} } sort keys %Salutations;

            # find signature id
            my %Signatures = $Kernel::OM->Get('Kernel::System::Signature')->SignatureList();
            my ($SignatureID) = grep { $NewQueue{Signature} eq $Signatures{$_} } sort keys %Signatures;

            # add queue
            my $Success = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
                Name              => $NewQueue{Name},
                ValidID           => $ValidID || 1,
                GroupID           => $GroupID || 1,
                Calendar          => $NewQueue{Calendar},
                FirstResponseTime => $NewQueue{FirstResponseTime},
                UpdateTime        => $NewQueue{UpdateTime},
                SolutionTime      => $NewQueue{SolutionTime},
                UnlockTimeout     => $NewQueue{UnlockTimeout},
                SystemAddressID   => $SystemAddressID || 1,
                SalutationID      => $SalutationID || 1,
                SignatureID       => $SignatureID || 1,
                Comment           => $NewQueue{Comment},
                UserID            => 1,
            );

            # error handling
            if ( !$Success ) {
                $Self->PrintError("Can't create queue $NewQueue{Name}.\n");
                return $Self->ExitCodeError();
            }
        }
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;

