package Koha::Illbatch;

# Copyright PTFS Europe 2022
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;
use Koha::Database;
use Koha::Illrequest::Logger;
use Koha::IllbatchStatus;
use JSON qw( to_json );
use base qw(Koha::Object);

=head1 NAME

Koha::Illbatch - Koha Illbatch Object class

=head2 Class methods

=head3 status

    my $status = Koha::Illbatch->status;

Return the status object associated with this batch

=cut

sub status {
    my ( $self ) = @_;
    return Koha::IllbatchStatus->_new_from_dbic(
        scalar $self->_result->statuscode
    );
}

=head3 patron

    my $patron = Koha::Illbatch->patron;

Return the patron object associated with this batch

=cut

sub patron {
    my ( $self ) = @_;
    return Koha::Patron->_new_from_dbic(
        scalar $self->_result->borrowernumber
    );
}

=head3 branch

    my $branch = Koha::Illbatch->branch;

Return the branch object associated with this batch

=cut

sub branch {
    my ( $self ) = @_;
    return Koha::Library->_new_from_dbic(
        scalar $self->_result->branchcode
    );
}

=head3 requests_count

    my $requests_count = Koha::Illbatch->requests_count;

Return the number of requests associated with this batch

=cut

sub requests_count {
    my ( $self ) = @_;
    return Koha::Illrequests->search({
        batch_id => $self->id
    })->count;
}

=head3 create_and_log

    $batch->create_and_log;

Log batch creation following storage

=cut

sub create_and_log {
    my ( $self ) = @_;

    $self->store;

    my $logger = Koha::Illrequest::Logger->new;

    $logger->log_something({
        modulename   => 'ILL',
        actionname  => 'batch_create',
        objectnumber => $self->id,
        infos        => to_json({})
    });
}

=head3 update_and_log

    $batch->update_and_log;

Log batch update following storage

=cut

sub update_and_log {
    my ( $self, $params ) = @_;

    my $before = {
        name       => $self->name,
        branchcode => $self->branchcode
    };

    $self->set( $params );
    my $update = $self->store;

    my $after = {
        name       => $self->name,
        branchcode => $self->branchcode
    };

    my $logger = Koha::Illrequest::Logger->new;

    $logger->log_something({
        modulename   => 'ILL',
        actionname  => 'batch_update',
        objectnumber => $self->id,
        infos        => to_json({
            before => $before,
            after  => $after
        })
    });
}

=head3 delete_and_log

    $batch->delete_and_log;

Log batch delete

=cut

sub delete_and_log {
    my ( $self ) = @_;

    my $logger = Koha::Illrequest::Logger->new;

    $logger->log_something({
        modulename   => 'ILL',
        actionname  => 'batch_delete',
        objectnumber => $self->id,
        infos        => to_json({})
    });

    $self->delete;
}

=head3 load_backend

Require "Base.pm" from the relevant ILL backend.

=cut

sub load_backend {
    my ( $self, $backend_id ) = @_;

    my @raw = qw/Koha Illbackends/; # Base Path

    my $backend_name = $backend_id || $self->backend;

    unless ( defined $backend_name && $backend_name ne '' ) {
        Koha::Exceptions::Ill::InvalidBackendId->throw(
            "An invalid backend ID was requested ('')");
    }

    my $location = join "/", @raw, $backend_name, "Base.pm";    # File to load
    my $backend_class = join "::", @raw, $backend_name, "Base"; # Package name

    require $location;
    $self->{_my_backend} = $backend_class->new({
        config => $self->_config,
        logger => Koha::Illrequest::Logger->new
    });

    return $self;
}


=head3 _backend

    my $backend = $abstract->_backend($new_backend);
    my $backend = $abstract->_backend;

Getter/Setter for our API object.

=cut

sub _backend {
    my ( $self, $backend ) = @_;
    $self->{_my_backend} = $backend if ( $backend );
    # Dynamically load our backend object, as late as possible.
    $self->load_backend unless ( $self->{_my_backend} );
    return $self->{_my_backend};
}

=head3 _backend_capability

    my $backend_capability_result = $self->_backend_capability($name, $args);

This is a helper method to invoke optional capabilities in the backend.  If
the capability named by $name is not supported, return 0, else invoke it,
passing $args along with the invocation, and return its return value.

NOTE: this module suffers from a confusion in termninology:

in _backend_capability, the notion of capability refers to an optional feature
that is implemented in core, but might not be supported by a given backend.

in capabilities & custom_capability, capability refers to entries in the
status_graph (after union between backend and core).

The easiest way to fix this would be to fix the terminology in
capabilities & custom_capability and their callers.

=cut

sub _backend_capability {
    my ( $self, $name, $args ) = @_;
    my $capability = 0;
    # See if capability is defined in backend
    
    # try {
        $capability = $self->_backend->capabilities($name);
    # } catch {
    #     warn $_;
    #     return 0;
    # };

    # Try to invoke it
    if ( $capability && ref($capability) eq 'CODE' ) {
        return &{$capability}($args);
    } else {
        return 0;
    }
}

=head3 backend_get_batch_update

    my $update = backend_get_update($request);

    Given a request, returns an update in a prescribed
    format that can then be passed to update parsers

=cut

sub backend_get_batch_update {
    my ( $self, $options ) = @_;

    my $response = $self->_backend_capability(
        'get_supplier_batch_update',
        {
            batch => $self,
            %{$options}
        }
    );
    return $response;
}

=head3 attach_batch_processors

Receive a Koha::Illrequest::SupplierUpdate and attach
any processors we have for it

=cut

sub attach_batch_processors {
    my ( $self, $update ) = @_;

    foreach my $processor(@{$self->{processors}}) {
        if (
            $processor->{target_source_type} eq $update->{source_type} &&
            $processor->{target_source_name} eq $update->{source_name}
        ) {
            $update->attach_processor($processor);
        }
    }
}

=head3 _config

    my $config = $abstract->_config($config);
    my $config = $abstract->_config;

Getter/Setter for our config object.

=cut

sub _config {
    my ( $self, $config ) = @_;
    $self->{_my_config} = $config if ( $config );
    # Load our config object, as late as possible.
    unless ( $self->{_my_config} ) {
        $self->{_my_config} = Koha::Illrequest::Config->new;
    }
    return $self->{_my_config};
}

=head2 Internal methods

=head3 _type

    my $type = Koha::Illbatch->_type;

Return this object's type

=cut

sub _type {
    return 'Illbatch';
}

=head1 AUTHOR

Andrew Isherwood <andrew.isherwood@ptfs-europe.com>

=cut

1;
