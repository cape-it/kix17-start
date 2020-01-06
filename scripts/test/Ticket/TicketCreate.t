# --
# Copyright (C) 2006-2020 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $TicketObject       = $Kernel::OM->GetNew('Kernel::System::Ticket');
my $UnitTestDataObject = $Kernel::OM->GetNew('Kernel::System::UnitTest:Data');

# define needed variables
my %TestData = (
    'Ticket' => {
        'Title'         => 'Test Ticket Title',
        'Queue'         => 'Raw',
        'Lock'          => 'unlock',
        'Priority'      => '3 normal',
        'State'         => 'new',
        'Type'          => 'Incident',
        'Service'       => 'Test Service',
        'SLA'           => 'Test SLA',
        'CustomerID'    => 'TestCustomerCompany',
        'CustomerUser'  => 'test@cape-it.de',
        'OwnerID'       => 1,
        'ResponsibleID' => 1,
        'UserID'        => 1,
    },
);
my $StartTime;
my $Success;

# init test case
$Self->TestCaseStart(
    TestCase    => 'Ticket Create',
    Feature     => 'Ticket',
    Story       => 'Create Ticket',
    Description => <<"END",
Create a new ticket with valid values of all available default ticket attributes:
* Ticket type
* Ticket status
* Ticket queue
* Ticket priority
* Ticket customer contact
* Ticket customer company
* Ticket service
* Ticket service level agreement
* Ticket owner
* Ticket responsible
* Ticket title
END
);

# init test steps
$Self->{'TestCase'}->{'PlanSteps'} = {
    '0001' => 'Prepare Test Data',
    '0002' => 'Ticket Create',
    '0003' => 'Ticket Check',
};

# begin transaction on database
$Self->Database_BeginWork();

# TEST STEP
# create test data
delete( $Self->{'TestCase'}->{'PlanSteps'}->{'0001'} );
$StartTime = $Self->GetMilliTimeStamp();
# prepare test data
$Success = $Self->True(
    TestName   => 'Prepare Test Data',
    TestValue  => $UnitTestDataObject->Ticket_Prepare( %TestData ),
    StartTime  => $StartTime,
);
return 1 if ( !$Success );
# EO TEST STEP

# get test data for ticket
my %TestTicketCreateData = %{ $TestData{'Ticket'} };
my %TestTicketCheckData  = $UnitTestDataObject->Ticket_CheckPrepare( %{ $TestData{'Ticket'} } );

# TEST STEP
# create test ticket
delete( $Self->{'TestCase'}->{'PlanSteps'}->{'0002'} );
$StartTime = $Self->GetMilliTimeStamp();
my $TicketID = $TicketObject->TicketCreate( %TestTicketCreateData );
$Success = $Self->IsNot(
    TestName   => 'Ticket Create',
    CheckValue => undef,
    TestValue  => $TicketID,
    StartTime  => $StartTime,
);
return 1 if ( !$Success );
# EO TEST STEP

# TEST STEP
# get and compare test ticket
delete( $Self->{'TestCase'}->{'PlanSteps'}->{'0003'} );
$StartTime = $Self->GetMilliTimeStamp();
my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
    Silent        => 1,
);
$Success = $Self->IsDeeply(
    TestName   => 'Ticket Check',
    CheckValue => \%TestTicketCheckData,
    TestValue  => \%Ticket,
    StartTime  => $StartTime,
);
return 1 if ( !$Success );
# EO TEST STEP

# rollback transaction on database
$Self->Database_Rollback();

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut