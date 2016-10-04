# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::ImportCommand;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::CSV',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Console::ImportCommand - import command base class

=head1 SYNOPSIS

Base class for object import commands.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item Configure()

Common configuration:

=over 2

=item * Description

=item * Output filename argument

=back

Requires C<< $Self->{ObjectClass} >> to be defined in the parent class.

=cut

sub Configure {
    my ( $Self, %Param ) = @_;

    ( $Self->{ObjectName} = $Self->{ObjectClass} ) =~ s/^.*:://;

    $Self->{DataObject} = $Kernel::OM->Get($Self->{ObjectClass});

    $Self->Description("Imports $Self->{ObjectName}s from a CSV file.");

    $Self->AddArgument(
        Name        => 'file',
        Description => "Specify the name for exported data.",
        Required    => 1,
        ValueRegex  => qr/.*\.csv/smxi,
    );

    return;
}

=item PreRun()

Checks if the specifed file is found.

=cut

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

=item Run()

Common code for all export commands.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Starting $Self->{ObjectName}s import...</yellow>\n");

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $CSV = Text::CSV->new(
        {
            quote_char  => '"',
            sep_char    => ',',
            binary      => 1,
        }
    );

    # open file for reading with UTF-8 encoding
    open my $FileHandle, "<:encoding(utf8)", $Self->GetArgument('file') || return $Self->ExitCodeError();

    # Read header line
    if ( my $HeaderRef = $CSV->getline($FileHandle) ) {

        ROW:
        # Go through the file, reading each group definition
        while ( my $ColRef = $CSV->getline($FileHandle) ) {
            my @ColumnNames = @{ $HeaderRef };
            my @Columns = @{ $ColRef };
            my ($ColumnName, $ColumnText);

            my %NewObject = ();

            COLUMN:
            while ( $ColumnName = shift @ColumnNames ) {
                $ColumnText = shift @Columns;

                my ( $Key, $Value ) = $Self->ObjectProperty( $ColumnName, $ColumnText );

                next ROW if !$Key;

                $NewObject{$Key} = $Value if $Value;
            }

            $NewObject{UserID} = 1;

            # add object
            my $Success = $Self->ObjectAdd( %NewObject );

            # error handling
            if ( !$Success ) {
                $Self->PrintError("Can't create $Self->{ObjectName} $NewObject{Name}.\n");
                return $Self->ExitCodeError();
            }

            $Self->Print("Added $Self->{ObjectName} \"$NewObject{Name}\".\n"); 
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

