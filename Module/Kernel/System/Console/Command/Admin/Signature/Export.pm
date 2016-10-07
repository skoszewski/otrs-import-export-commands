# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Signature::Export;

use strict;
use warnings;

use MIME::Base64;
use Encode;

use base qw(Kernel::System::Console::ExportCommand);

our @ObjectDependencies = (
    'Kernel::System::Signature',
    'Kernel::System::Valid',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->{ColumnNames} = [
        "Name",
        "Content Type",
        "Valid",
        "Comment",
        "Text",
    ];

    $Self->{ObjectClass} = 'Kernel::System::Signature';

    $Self->SUPER::Configure();

    return;
}

sub ObjectList {
    my ($Self) = @_;

    return $Self->{DataObject}->SignatureList();
}

sub ObjectGet {
    my ( $Self, $ObjectId ) = @_;

    my %Object = $Self->{DataObject}->SignatureGet( ID => $ObjectId );

    # return a list reference
    return [
        $Object{Name},
        $Object{ContentType},
        $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( ValidID => $Object{ValidID} ),
        $Object{Comment},
        encode_base64( Encode::encode_utf8( $Object{Text} ), '' ),
    ];
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
