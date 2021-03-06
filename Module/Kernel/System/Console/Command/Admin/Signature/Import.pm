# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Signature::Import;

use strict;
use warnings;

use MIME::Base64;
use Encode;

use base qw(Kernel::System::Console::ImportCommand);

our @ObjectDependencies = (
    'Kernel::System::Signature',
    'Kernel::System::Valid',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ObjectClass}   = 'Kernel::System::Signature';
    $Self->{CacheType}     = 'Signature';
    $Self->{PropertyNames} = [
        "Name",
        "Text",
        "ContentType",
        "Comment",
        "ValidID",
    ];

    $Self->SUPER::Configure();

    my %ReversedSignatureList = reverse $Self->{DataObject}->SignatureList( Valid => 0 );
    $Self->{ObjectList} = \%ReversedSignatureList;

    return;
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    return $Self->{DataObject}->SignatureGet(
        ID => $ObjectId
    );
}

sub ObjectProperty {
    my ( $Self, $ColumnName, $ColumnText ) = @_;

    if ( $ColumnName =~ m/^name$/i ) {    # Name
        return ( 'Name', $ColumnText );
    }
    elsif ( $ColumnName =~ m/^content *type$/i ) {    # Content Type
        return ( 'ContentType', $ColumnText || '' );
    }
    elsif ( $ColumnName =~ m/^valid$/i ) {            # Valid
        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => $ColumnText );
        return ( 'ValidID', $ValidID || 1 );
    }
    elsif ( $ColumnName =~ m/^comment$/i ) {          # Comment
        return ( 'Comment', $ColumnText || '' );
    }
    elsif ( $ColumnName =~ m/^text$/i ) {             # Base64 encoded text
        return ( 'Text', Encode::decode_utf8( decode_base64( $ColumnText || '' ) ) );
    }

    return;
}

sub ObjectAdd {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->SignatureAdd(%NewObject);
}

sub ObjectUpdate {
    my ( $Self, %NewObject ) = @_;

    return $Self->{DataObject}->SignatureUpdate(%NewObject);
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
