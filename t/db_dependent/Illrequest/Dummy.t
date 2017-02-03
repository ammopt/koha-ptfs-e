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

use Koha::Database;
use Koha::Illrequests;
use t::lib::TestBuilder;

use Test::More tests => 15;

# This is a set of basic tests for the Dummy backend, largely to provide
# sanity checks for testing at the higher level Illrequest.pm level.
#
# The Dummy backend is rather simple, but provides correctly formatted
# response values, that other backends can model themselves after.

use_ok('Koha::Illrequest::Backend::Dummy');

my $backend = Koha::Illrequest::Backend::Dummy->new;

isa_ok($backend, 'Koha::Illrequest::Backend::Dummy');


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
    }
});
my $mock_request = Koha::Illrequests->find($illRequest->{illrequest_id});
$mock_request->_config->backend("Dummy");
$mock_request->_config->limits({ default => { count => -1 } });

# Test Create
my $rq = $backend->create({
    request    => $mock_request,
    method     => 'create',
    stage      => 'search_form',
    other      => undef,
});

is_deeply(
    $rq,
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'create',
        stage   => 'search_form',
        value   => {},
    },
    "Search_Form stage of create method."
);

$rq = $backend->create({
    request    => $mock_request,
    method     => 'create',
    stage      => 'search_results',
    other      => { search => "interlibrary loans" },
});

is_deeply(
    $rq,
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'create',
        stage   => 'search_results',
        value   => [
            {
                id     => 1234,
                title  => "Ordering ILLs using Koha",
                author => "A.N. Other",
            },
            {
                id     => 5678,
                title  => "Interlibrary loans in Koha",
                author => "A.N. Other",
            },
        ],
    },
    "Search_Results stage of create method."
);

$rq = $backend->create({
    request    => $mock_request,
    method     => 'create',
    stage      => 'commit',
    other      => {
        id     => 1234,
        title  => "Ordering ILLs using Koha",
        author => "A.N. Other",
    },
});

is_deeply(
    $rq,
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'create',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other"
        },
    },
    "Commit stage of create method."
);

$rq = $backend->create({
    request    => $mock_request,
    method     => 'create',
    stage      => 'unknown_stage',
    other      => {
        id     => 1234,
        title  => "Ordering ILLs using Koha",
        author => "A.N. Other",
    },
});

is_deeply(
    $rq,
    {
        error   => 1,
        status  => 'unknown_stage',
        message => '',
        method  => 'create',
        stage   => 'unknown_stage',
        value   => {},
    },
    "Commit stage of create method."
);

# Test Confirm

$rq = $backend->confirm({
    request    => $mock_request,
    other      => undef,
});

is_deeply(
    $rq,
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'confirm',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "On order",
            cost   => "30 GBP",
        },
    },
    "Basic confirm method."
);

# Test List

is_deeply(
    $backend->list,
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'list',
        stage   => 'commit',
        value   => {
            1 => {
                id     => 1234,
                title  => "Ordering ILLs using Koha",
                author => "A.N. Other",
                status => "On order",
                cost   => "30 GBP",
            },
        },
    },
    "Basic list method."
);

# Test Renew

is_deeply(
    $backend->renew({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 1,
        status  => 'not_renewed',
        message => 'Order not yet delivered.',
        method  => 'renew',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "On order",
        },
    },
    "Basic renew method."
);

Koha::Illrequestattributes->find({
    illrequest_id => $mock_request->illrequest_id,
    type          => "status"
})->set({ value => "Delivered" })->store;

is_deeply(
    $backend->renew({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'renew',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "Renewed",
        },
    },
    "Modified renew method."
);

# Test Update_Status

is_deeply(
    $backend->update_status({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 1,
        status  => 'failed_update_hook',
        message => 'Fake reason for failing to perform update operation.',
        method  => 'update_status',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "Delivered",
        },
    },
    "Basic update_status method."
);

# FIXME: Perhaps we should add a test checking for specific status code
# transitions.

# Test Cancel

is_deeply(
    $backend->cancel({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'cancel',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "Delivered",
        },
    },
    "Basic cancel method."
);

is_deeply(
    $backend->cancel({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 1,
        status  => 'unknown_request',
        message => 'Cannot cancel an unknown request.',
        method  => 'cancel',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
        },
    },
    "Attempt to cancel an unconfirmed request."
);

# Test Status

is_deeply(
    $backend->status({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 1,
        status  => 'unknown_request',
        message => 'Cannot query status of an unknown request.',
        method  => 'status',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
        },
    },
    "Attempt to get status of an unconfirmed request."
);

$rq = $backend->confirm({
    request    => $mock_request,
    other      => undef,
});

is_deeply(
    $backend->status({
        request    => $mock_request,
        other      => undef,
    }),
    {
        error   => 0,
        status  => '',
        message => '',
        method  => 'status',
        stage   => 'commit',
        value   => {
            id     => 1234,
            title  => "Ordering ILLs using Koha",
            author => "A.N. Other",
            status => "On order",
        },
    },
    "Basic status method."
);

1;
