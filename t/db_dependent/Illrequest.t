#!/usr/bin/perl
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#

use Modern::Perl;

use File::Basename qw/basename/;
use Koha::Database;
use Koha::Illrequestattributes;
use Koha::Patrons;
use t::lib::TestBuilder;

use Test::More tests => 44;

# We want to test the Koha IllRequest object.  At its core it's a simple
# Koha::Object, mapping to the ill_request table.
#
# This object will supersede the Status object in ILLModule.
#
# We must ensure perfect backward compatibility between the current model and
# the Status less model.

use_ok('Koha::Illrequest');
use_ok('Koha::Illrequests');

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new;

my $patron = $builder->build({ source => 'Borrower' });
my $branch = $builder->build({ source => 'Branch' });

my $illRequest = $builder->build({
    source => 'Illrequest',
    value => {
        borrowernumber  => $patron->{borrowernumber},
        branch          => $branch->{branchcode},
        biblionumber    => 0,
        status          => 'NEW',
        completion_date => 0,
        reqtype         => 'book',
    }
});

my $illObject = Koha::Illrequests->find($illRequest->{illrequest_id});

isa_ok($illObject, "Koha::Illrequest");

# Test delete works correctly.
my $illRequestDelete = $builder->build({
    source => 'Illrequest',
    value => {
        borrowernumber  => $patron->{borrowernumber},
        branch          => $branch->{branchcode},
        biblionumber    => 0,
        status          => 'NEW',
        completion_date => 0,
        reqtype         => 'book',
    }
});
sub ill_req_search {
    return Koha::Illrequestattributes->search({
        illrequest_id => $illRequestDelete->{illrequest_id}
    })->count;
}

is(ill_req_search, 0, "Correctly not found matching Illrequestattributes.");
# XXX: For some reason test builder can't build Illrequestattributes.
my $illReqAttr = Koha::Illrequestattribute->new({
    illrequest_id => $illRequestDelete->{illrequest_id},
    type => "test",
    value => "Hello World"
})->store;
is(ill_req_search, 1, "We have found a matching Illrequestattribute.");

Koha::Illrequests->find($illRequestDelete->{illrequest_id})->delete;
is(
    Koha::Illrequests->find($illRequestDelete->{illrequest_id}),
    undef,
    "Correctly deleted Illrequest."
);
is(ill_req_search, 0, "Correctly deleted Illrequestattributes.");

# Test Accessing of related records.

# # TODO the conclusion from being able to use one_to_many? we no longer need
# # the Record object: simply pass the `ill_request_attributes` resultset
# # whenever one would pass a Record.

my $illRequest2 = $builder->build({
    source => 'Illrequest',
    value  => {
        borrower_id => $patron->{borrowernumber},
        branch_id   => $branch->{branchcode},
        biblio_id   => 0,
        status      => 'NEW',
        completed   => 0,
        medium      => 'book',
    }
});
my $illReqAttr2 = Koha::Illrequestattribute->new({
    illrequest_id => $illRequest2->{illrequest_id},
    type          => "test2",
    value         => "Hello World"
})->store;
my $illReqAttr3 = Koha::Illrequestattribute->new({
    illrequest_id => $illRequest2->{illrequest_id},
    type          => "test3",
    value         => "Hello Space"
})->store;

my $illRequestAttributes = Koha::Illrequests
    ->find($illRequest2->{illrequest_id})->illrequestattributes;

isa_ok($illRequestAttributes, "Koha::Illrequestattributes");

is($illRequestAttributes->count, 2, "Able to search related.");

# Test loading of 'Config'.

my $rqConfigTest = Koha::Illrequest->new({
    borrower_id => $patron->{borrowernumber},
    branch_id   => $branch->{branchcode},
});

isa_ok($rqConfigTest->_config, "Koha::Illrequest::Config");

# Test loading of 'Dummy' backend.

my $rqBackendTest = Koha::Illrequest->new({
    borrower_id => $patron->{borrowernumber},
    branch_id   => $branch->{branchcode},
})->store;

$rqBackendTest->_config->backend("Dummy");
$rqBackendTest->_config->limits({ default => { count => -1 } });
isa_ok($rqBackendTest->_backend, "Koha::Illbackends::Dummy::Base");

# Test use of 'Dummy' Backend.

## Test backend_update_status

# FIXME: This breaks transparancy of ->status method!
eval { $rqBackendTest->status("ERR") };
ok($@, "status: Test for status error on hook fail.");

# FIXME: Will need to test this on new illRequest to not pollute rest of
# tests.

# is($rqBackendTest->status("NEW")->status, "NEW", "status: Setter works
# OK.");
# is($rqBackendTest->status(null), null, "status: Unsetter works OK.");

## Test backend_create

is(
    $rqBackendTest->status,
    undef,
    "backend_create: Test our status initiates correctly."
);

# Request a search form
my $created_rq = $rqBackendTest->backend_create({
    stage  => "search_form",
    method => "create",
});

is( $created_rq->{stage}, 'search_results',
    "backend_create: search_results stage." );

# Request search results
# FIXME: fails because of missing patron / branch info.
# $created_rq = $rqBackendTest->backend_create({
#     stage  => "search_results",
#     method => "create",
#     other  => { search => "interlibrary loans" },
# });

# is_deeply(
#     $created_rq,
#     {
#         error    => 0,
#         status   => '',
#         message  => '',
#         method   => 'create',
#         stage    => 'search_results',
#         template => 'ill/Dummy/create.inc',
#         value    => [
#             {
#                 id     => 1234,
#                 title  => "Ordering ILLs using Koha",
#                 author => "A.N. Other",
#             },
#             {
#                 id     => 5678,
#                 title  => "Interlibrary loans in Koha",
#                 author => "A.N. Other",
#             },
#         ],
#     }
#     ,
#     "backend_create: search_results stage."
# );

# # Create the request
# $created_rq = $rqBackendTest->backend_create({
#     stage  => "commit",
#     method => "create",
#     other  => {
#         id     => 1234,
#         title  => "Ordering ILLs using Koha",
#         author => "A.N. Other",
#     },
# });

# while ( my ( $field, $value ) = each %{$created_rq} ) {
#     isnt($value, undef, "backend_create: key '$field' exists");
# };

# is(
#     $rqBackendTest->status,
#     "NEW",
#     "backend_create: Test our status was updated."
# );

# cmp_ok(
#     $rqBackendTest->illrequestattributes->count,
#     "==",
#     3,
#     "backend_create: Ensure we have correctly stored our new attributes."
# );

# ## Test backend_list

# is_deeply(
#     $rqBackendTest->backend_list->{value},
#     {
#         1 => {
#             id     => 1234,
#             title  => "Ordering ILLs using Koha",
#             author => "A.N. Other",
#             status => "On order",
#             cost   => "30 GBP",
#         }
#     },
#     "backend_list: Retrieve our list of requested requests."
# );

# ## Test backend_renew

# ok(
#     $rqBackendTest->backend_renew->{error},
#     "backend_renew: Error for invalid request."
# );
# is_deeply(
#     $rqBackendTest->backend_renew->{value},
#     {
#         id     => 1234,
#         title  => "Ordering ILLs using Koha",
#         author => "A.N. Other",
#     },
#     "backend_renew: Renew request."
# );

# ## Test backend_confirm

# my $rqBackendTestConfirmed = $rqBackendTest->backend_confirm;
# is(
#     $rqBackendTest->status,
#     "REQ",
#     "backend_commit: Confirm status update correct."
# );
# is(
#     $rqBackendTest->orderid,
#     1234,
#     "backend_commit: Confirm orderid populated correctly."
# );

# ## Test backend_status

# is(
#     $rqBackendTest->backend_status->{error},
#     0,
#     "backend_status: error for invalid request."
# );
# is_deeply(
#     $rqBackendTest->backend_status->{value},
#     {
#         id     => 1234,
#         status => "On order",
#         title  => "Ordering ILLs using Koha",
#         author => "A.N. Other",
#     },
#     "backend_status: Retrieve the status of request."
# );

# # Now test trying to get status on non-confirmed request.
my $rqBackendTestUnconfirmed = Koha::Illrequest->new({
    borrower_id => $patron->{borrowernumber},
    branch_id   => $branch->{branchcode},
})->store;
$rqBackendTestUnconfirmed->_config->backend("Dummy");
$rqBackendTestUnconfirmed->_config->limits({ default => { count => -1 } });

$rqBackendTestUnconfirmed->backend_create({
    stage  => "commit",
    method => "create",
    other  => {
        id     => 1234,
        title  => "Ordering ILLs using Koha",
        author => "A.N. Other",
    },
});
is(
    $rqBackendTestUnconfirmed->backend_status->{error},
    1,
    "backend_status: error for invalid request."
);

## Test backend_cancel

# is(
#     $rqBackendTest->backend_cancel->{error},
#     0,
#     "backend_cancel: Successfully cancelling request."
# );
# is_deeply(
#     $rqBackendTest->backend_cancel->{value},
#     {
#         id     => 1234,
#         title  => "Ordering ILLs using Koha",
#         author => "A.N. Other",
#     },
#     "backend_cancel: Cancel request."
# );

# Now test trying to cancel non-confirmed request.
is(
    $rqBackendTestUnconfirmed->backend_cancel->{error},
    1,
    "backend_cancel: error for invalid request."
);
is_deeply(
    $rqBackendTestUnconfirmed->backend_cancel->{value},
    {},
    "backend_cancel: Cancel request."
);

# Test Helpers

## Test getCensorNotesStaff

is($rqBackendTest->getCensorNotesStaff, 1, "getCensorNotesStaff: Public.");
$rqBackendTest->_config->censorship({
    censor_notes_staff => 0,
    censor_reply_date  => 0,
});
is($rqBackendTest->getCensorNotesStaff, 0, "getCensorNotesStaff: Censored.");

## Test getCensorNotesStaff

is($rqBackendTest->getDisplayReplyDate, 1, "getDisplayReplyDate: Yes.");
$rqBackendTest->_config->censorship({
    censor_notes_staff => 0,
    censor_reply_date  => 1,
});
is($rqBackendTest->getDisplayReplyDate, 0, "getDisplayReplyDate: No.");

# FIXME: These should be handled by the templates.
# # Test Output Helpers

# ## Test getStatusSummary

# $rqBackendTest->medium("Book")->store;
# is_deeply(
#     $rqBackendTest->getStatusSummary({brw => 0}),
#     {
#         biblionumber => ["Biblio Number", undef],
#         borrowernumber => ["Borrower Number", $patron->{borrowernumber}],
#         id => ["Request Number", $rqBackendTest->illrequest_id],
#         prefix_id => ["Request Number", $rqBackendTest->illrequest_id],
#         reqtype => ["Request Type", "Book"],
#         status => ["Status", "REQREV"],
#     },
#     "getStatusSummary: Without Borrower."
# );

# is_deeply(
#     $rqBackendTest->getStatusSummary({brw => 1}),
#     {
#         biblionumber => ["Biblio Number", undef],
#         borrower => ["Borrower", Koha::Patrons->find($patron->{borrowernumber})],
#         id => ["Request Number", $rqBackendTest->illrequest_id],
#         prefix_id => ["Request Number", $rqBackendTest->illrequest_id],
#         reqtype => ["Request Type", "Book"],
#         status => ["Status", "REQREV"],
#     },
#     "getStatusSummary: With Borrower."
# );

# ## Test getFullStatus

# is_deeply(
#     $rqBackendTest->getFullStatus({brw => 0}),
#     {
#         biblionumber => ["Biblio Number", undef],
#         borrowernumber => ["Borrower Number", $patron->{borrowernumber}],
#         id => ["Request Number", $rqBackendTest->illrequest_id],
#         prefix_id => ["Request Number", $rqBackendTest->illrequest_id],
#         reqtype => ["Request Type", "Book"],
#         status => ["Status", "REQREV"],
#         placement_date => ["Placement Date", $rqBackendTest->placed],
#         completion_date => ["Completion Date", $rqBackendTest->completed],
#         ts => ["Timestamp", $rqBackendTest->updated],
#         branch => ["Branch", $rqBackendTest->branch_id],
#     },
#     "getFullStatus: Without Borrower."
# );

# is_deeply(
#     $rqBackendTest->getFullStatus({brw => 1}),
#     {
#         biblionumber => ["Biblio Number", undef],
#         borrower => ["Borrower", Koha::Patrons->find($patron->{borrowernumber})],
#         id => ["Request Number", $rqBackendTest->illrequest_id],
#         prefix_id => ["Request Number", $rqBackendTest->illrequest_id],
#         reqtype => ["Request Type", "Book"],
#         status => ["Status", "REQREV"],
#         placement_date => ["Placement Date", $rqBackendTest->placed],
#         completion_date => ["Completion Date", $rqBackendTest->completed],
#         ts => ["Timestamp", $rqBackendTest->updated],
#         branch => ["Branch", $rqBackendTest->branch_id],
#     },
#     "getFullStatus: With Borrower."
# );

## Test available_backends
subtest 'available_backends' => sub {
    plan tests => 1;

    my $rq = Koha::Illrequest->new({
        borrower_id => $patron->{borrowernumber},
        branch_id   => $branch->{branchcode},
    })->store;

    my @backends = ();
    my $backenddir = $rq->_config->backend_dir;
    @backends = <$backenddir/*> if ( $backenddir );
    @backends = map { basename($_) } @backends;
    is_deeply(\@backends, $rq->available_backends,
              "Correctly identify available backends.");

};

## Test capabilities

my $rqCapTest = Koha::Illrequest->new({
    borrower_id => $patron->{borrowernumber},
    branch_id   => $branch->{branchcode},
})->store;

is( keys %{$rqCapTest->_core_status_graph},
    @{[ 'NEW', 'REQ', 'REVREQ', 'QUEUED', 'CANCREQ', 'COMP', 'KILL' ]},
    "Complete list of core statuses." );

my $union = $rqCapTest->_status_graph_union(
    $rqCapTest->_core_status_graph,
    {
        TEST => {
            prev_actions => [ 'COMP' ],
            id           => 'TEST',
            name         => "Test",
            ui_method_name => "Perform test",
            method         => 'test',
            next_actions   => [ 'NEW' ]
        },
        BLAH => {
            prev_actions => [ 'COMP' ],
            id           => 'BLAH',
            name         => "BLAH",
            ui_method_name => "Perform test",
            method         => 'test',
            next_actions   => [ 'NEW' ]
        },
    }
);
ok( ( grep 'BLAH', @{$union->{COMP}->{next_actions}} and
          grep 'TEST', @{$union->{COMP}->{next_actions}} ),
    "next_actions: updated." );
ok( ( grep 'BLAH', @{$union->{NEW}->{prev_actions}} and
          grep 'TEST', @{$union->{NEW}->{prev_actions}} ),
    "next_actions: updated." );

## Test available_backends
subtest 'available_actions' => sub {
    plan tests => 1;

    my $rq = Koha::Illrequest->new({
        borrower_id => $patron->{borrowernumber},
        branch_id   => $branch->{branchcode},
        status      => 'NEW',
    })->store;

    is_deeply(
        $rq->available_actions,
        [
            {
                prev_actions   => [ 'NEW', 'REQREV', 'QUEUED' ],
                id             => 'REQ',
                name           => 'Requested',
                ui_method_name => 'Create request',
                method         => 'confirm',
                next_actions   => [ 'REQREV' ],
            },
            {
                prev_actions   => [ 'CANCREQ', 'QUEUED', 'REQREV', 'NEW' ],
                id             => 'KILL',
                name           => 0,
                ui_method_name => 'Delete request',
                method         => 'delete',
                next_actions   => [ ],
            }
        ]
    );
};

$schema->storage->txn_rollback;

1;
