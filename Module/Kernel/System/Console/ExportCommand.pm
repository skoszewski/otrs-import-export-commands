# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::ExportCommand;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::CSV',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Console::ExportCommand - export command base class

=head1 SYNOPSIS

Base class for object export commands.

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

    $Self->Description("Exports all $Self->{ObjectName}s to a CSV file.");

    $Self->AddArgument(
        Name        => 'file',
        Description => "Specify the name for exported data.",
        Required    => 1,
        ValueRegex  => qr/.*\.csv/smxi,
    );

    return;
}

=item Run()

Common code for all export commands. Calls three methods which should be
overriden in parent classes.

=over 2

=item * ObjectList() - Returns a hash with B<Id>, B<Name> pairs.

=item * ObjectGet() - Returns a hash with object properties.

Takes a hash as an argument with I<ID> as the only key. The first list item
should be object name.

=back

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Export starting...</yellow>\n");

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $CSVObject   = $Kernel::OM->Get('Kernel::System::CSV');

    my @Data;
    my %Objects = $Self->ObjectList();

    foreach my $Id (sort keys %Objects) {

        my $ObjectData = $Self->ObjectGet( $Id );

        $Self->Print("$Self->{ObjectName}: <green>@$ObjectData[0]</green>\n");
        
        push @Data, $ObjectData;
    }

    open my $FileHandle, ">:encoding(utf8)", $Self->GetArgument('file') || return $Self->ExitCodeError();

    my ($ExitCode, $ExitText);

    if (
        print $FileHandle $CSVObject->Array2CSV(
            Head       => $Self->{ColumnNames},
            Data       => \@Data,
            Separator  => ',',
            Quote      => '"',
            Format     => 'CSV',
        )
    ) {
        $ExitText = "<green>Done.</green>\n";
        $ExitCode = $Self->ExitCodeOk();
    } else {
        $ExitText = "<red>Cannot write output file, check filename and permissions!</red>\n";
        $ExitCode = $Self->ExitCodeError();
    }

    close $FileHandle;

    $Self->Print($ExitText);

    return $ExitCode;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

