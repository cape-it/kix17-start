# --
# Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::SMTP_OAuth2;

use strict;
use warnings;

use MIME::Base64 qw(encode_base64);

use parent qw(Kernel::System::Email::SMTP);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::OAuth2',
);

sub Check {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2');

    # get config data
    my %ConfigData = ();
    $ConfigData{FQDN}           = $ConfigObject->Get('FQDN');
    $ConfigData{Host}           = $ConfigObject->Get('SendmailModule::Host');
    $ConfigData{SMTPPort}       = $ConfigObject->Get('SendmailModule::Port');
    $ConfigData{AuthUser}       = $ConfigObject->Get('SendmailModule::AuthUser');
    $ConfigData{OAuth2_Profile} = $ConfigObject->Get('SendmailModule::OAuth2_Profile');

    # check needed stuff
    for (qw(Host AuthUser OAuth2_Profile)) {
        if ( !$ConfigData{$_} ) {
            return (
                Successful => 0,
                Message    => 'Need configuration SendmailModule::' . $_ . '!',
            );
        }
    }

    # lookup profile id
    my $ProfileID = $OAuth2Object->ProfileLookup(
        Name => $ConfigData{OAuth2_Profile},
    );
    if ( !$ProfileID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ID for OAuth2 profile '$ConfigData{OAuth2_Profile}' not found!"
        );
        return;
    }

    # authentication
    my $AccessToken = $OAuth2Object->GetAccessToken(
        ProfileID => $ProfileID,
    );

    if ( !$AccessToken ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not request access token for $ConfigData{AuthUser}/$ConfigData{Host}'. The refresh token could be expired or invalid."
        );
        return;
    }

    # try it 3 times to connect with the SMTP server
    # (M$ Exchange Server 2007 have sometimes problems on port 25)
    my $SMTP;
    TRY:
    for my $Try ( 1 .. 3 ) {

        # connect to mail server
        $SMTP = $Self->_Connect(
            MailHost  => $ConfigData{Host},
            FQDN      => $ConfigData{FQDN},
            SMTPPort  => $ConfigData{SMTPPort},
            SMTPDebug => $Self->{SMTPDebug},
        );

        last TRY if $SMTP;

        # sleep 0,3 seconds;
        sleep( 0.3 );
    }

    # return if no connect was possible
    if ( !$SMTP ) {
        return (
            Successful => 0,
            Message    => "Can't connect to $ConfigData{Host}: $!!",
        );
    }

    my $SASLXOAUTH2 = encode_base64( 'user=' . $Param{AuthUser} . "\x01auth=Bearer " . $AccessToken . "\x01\x01" );
    $SMTP->command( 'AUTH', 'XOAUTH2' )->response();
    my $NOM = $SMTP->command($SASLXOAUTH2)->response();

    if ( !defined $NOM ) {
        $SMTP->quit();
        return (
            Successful => 0,
            Message    => "Auth for user $ConfigData{AuthUser}/$ConfigData{Host} failed!"
        );
    }

    return (
        Successful => 1,
        SMTP       => $SMTP,
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
