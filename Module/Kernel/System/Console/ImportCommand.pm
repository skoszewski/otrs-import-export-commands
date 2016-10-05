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

use Text::CSV;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::CSV',
    'Kernel::System::Valid',
    'Kernel::System::Cache',
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

=over 4

=item * Description

=item * Output filename argument

=back

The base class implementation of C<Configure()> method expects to be overriden
and called from a child method using C<< $Self->SUPER::Configure() >>.

Several properties for the C<$Self> object must be also defined.

=over 4

=item * ObjectClass

=item * CacheType

=item * PropertyNames

=item * ObjectList

=back

The C<ObjectList> property must be defined B<AFTER> base class method
C<Configure()> has been called.

The example implementation for C<Kernel::System::Group> can be found below:

    sub Configure {
        my ( $Self, %Param ) = @_;

        $Self->{ObjectClass} = 'Kernel::System::Group';
        $Self->{CacheType} = 'Group';
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

=item ObjectGet()

Default method which should be overriden as the example below:

    sub ObjectGet {
        my ( $Self, $ObjectId ) = @_;

        return $Self->{DataObject}->GroupGet(
            ID => $ObjectId
        );
    }

=cut

sub ObjectGet {
    return;
}

=item ObjectProperty()

Default method which should be overriden. Returns a two element list
with a property name and value. Returns nothing if column name is unknown.

Example:

    sub ObjectProperty {
        my ( $Self, $ColumnName, $ColumnText ) = @_;

        if ( $ColumnName =~ m/^name$/i ) {          # Name
            return ( 'Name', $ColumnText );
        } elsif ( $ColumnName =~ m/^valid$/i ) {    # Valid
            my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText ); 
            return ( 'ValidID', $ValidID || 1 );
        } elsif ( $ColumnName =~ m/^comment$/i ) {  # Comment
            return ( 'Comment', $ColumnText || '' );
        }

        return;
    }

=cut

sub ObjectProperty {
    return;
}

=item ObjectAdd()

Default method which should be overriden.

Example:

    sub ObjectAdd {
        my ( $Self, %NewObject ) = @_;

        return $Self->{DataObject}->GroupAdd( %NewObject );
    }

=cut

sub ObjectAdd {
    return 0;
}

=item ObjectUpdate()

Default method which should be overriden.

Example:

    sub ObjectUpdate {
        my ( $Self, %NewObject ) = @_;

        return $Self->{DataObject}->GroupUpdate( %NewObject );
    }

=cut

sub ObjectUpdate {
    return 0;
}

=item ObjectCompare()

A method which compares selected object properties. It may be overridden
if custom object comparision alghoritm is required.

=cut

sub ObjectCompare {
    my ( $Self, $OldObject, $NewObject ) = @_;

    foreach my $Key ( @{ $Self->{PropertyNames} } ) {
        # return false if any property does not match or does not exist
        return if ! exists $OldObject->{$Key} || ! exists $NewObject->{$Key};
        return if $OldObject->{$Key} ne $NewObject->{$Key};
    }

    return 1;       # Objects are equal
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

                $NewObject{$Key} = $Value || '';
            }

            $NewObject{UserID} = 1;     # Add UserID which is mandatory in most calls.

            # Skip to the next row if "Name" was not defined
            next ROW if !$NewObject{Name};

            my ($Id, $Success);
            
            # check if object of the same name already exists
            $Id = $Self->{ObjectList}->{$NewObject{Name}};

            if ( $Id ) {
                # update object if alread exists
                my %OldObject = $Self->ObjectGet( $Id );
                if ( !$Self->ObjectCompare( \%OldObject, \%NewObject ) ) {
                    $NewObject{ID} = $Id;
                    $Success = $Self->ObjectUpdate( %NewObject );
                    
                    if ( $Success ) {
                       $Self->Print("Updated $Self->{ObjectName} \"$NewObject{Name}\".\n"); 
                    }
                } else {
                   $Self->Print("$Self->{ObjectName} \"$NewObject{Name}\" is up to date.\n"); 
                   $Success = 1;
                }
            } else {
                # add object a new object
                $Success = $Self->ObjectAdd( %NewObject );

                if ( $Success ) {
                    $Self->Print("Added $Self->{ObjectName} \"$NewObject{Name}\".\n");
                }
            }

            # error handling
            if ( !$Success ) {
                $Self->PrintError("Can't create $Self->{ObjectName} $NewObject{Name}.\n");
                return $Self->ExitCodeError();
            }
        }
    }

    if ( $Self->{CacheType} ) {
        # Delete cached objects before continuing
        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        $Self->Print("<yellow>Deleting $Self->{CacheType} cache...</yellow>\n");

        if ( !$CacheObject->CleanUp( Type => $Self->{CacheType} ) ) {
            $Self->ExitCodeError();
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

