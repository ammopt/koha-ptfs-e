package Koha::DBIx::Component::L10nSource;

use Modern::Perl;
use base 'DBIx::Class';

=head1 NAME

Koha::DBIx::Component::L10nSource

=head1 SYNOPSIS

    __PACKAGE__->load_components('+Koha::DBIx::Component::L10nSource')

    sub insert {
        my $self = shift;
        my $result = $self->next::method(@_);
        my @sources = $self->result_source->resultset->get_column('label')->all;
        $self->update_l10n_source('somecontext', @sources);
        return $result;
    }

    sub update {
        my $self = shift;
        my $is_column_changed = $self->is_column_changed('label');
        my $result = $self->next::method(@_);
        if ($is_column_changed) {
            my @sources = $self->result_source->resultset->get_column('label')->all;
            $self->update_l10n_source('somecontext', @sources);
        }
        return $result;
    }

    sub delete {
        my $self = shift;
        my $result = $self->next::method(@_);
        my @sources = $self->result_source->resultset->get_column('label')->all;
        $self->update_l10n_source('somecontext', @sources);
        return $result;
    }

=head1 METHODS

=head2 update_l10n_source

    $self->update_l10n_source($group, $key, $text)

Update or create an entry in l10n_source

=cut

sub update_l10n_source {
    my ( $self, $group, $original_text, $updated_text, $key ) = @_;

    my $l10n_source_rs_old =
      $self->result_source->schema->resultset('L10nSource')
      ->find( { group => $group, text => $original_text },
        { key => 'group_text' } );
    my $l10n_source_rs_new =
      $self->result_source->schema->resultset('L10nSource')
      ->find( { group => $group, text => $updated_text },
        { key => 'group_text' } );

    if ($l10n_source_rs_old) {
        warn "Found source";
        my $l10n_keys = $l10n_source_rs_old->l10n_keys;
        my $count     = $l10n_keys->count;
        if ( $count == 1 ) {
            warn "Found key";
            my $l10n_key = $l10n_keys->first;
            if ( $l10n_key->key eq $key ) {
                warn "It matched";

                # Move source link to existing match
                if ($l10n_source_rs_new) {
                    warn "Moving key";
                    $l10n_keys->search( { key => $key } )->update(
                        {
                            l10n_source_id =>
                              $l10n_source_rs_new->l10n_source_id
                        }
                    );
                    warn "Deleting source";
                    $l10n_source_rs_old->delete;
                }

                # Update existing source link and set translations to fuzzy
                else {
                    warn "Updating source";
                    $l10n_source_rs_old->update( { text => $updated_text } );
                    warn "Fuzzying translations";
                    my $l10n_target_rs = $l10n_source_rs_old->l10n_targets_rs;
                    $l10n_target_rs->update( { fuzzy => 1 } );
                }
            }
            else {
                #CHECK: We should never reach here
                warn "It didn't match";

                # Create new source link if required
                $l10n_source_rs_new //=
                  $self->result_source->schema->resultset('L10nSource')
                  ->create( { group => $group, text => $updated_text } );

                # Move source link to existing match
                $l10n_keys->search( { key => $key } )->update(
                    {
                        {
                            l10n_source_id =>
                              $l10n_source_rs_new->l10n_source_id
                        }
                    }
                );
            }
        }
        else {
            warn "Multiple keys";

            # Create new source link if required
            warn "Adding source" unless $l10n_source_rs_new;
            $l10n_source_rs_new //=
              $self->result_source->schema->resultset('L10nSource')
              ->create( { group => $group, text => $updated_text } );

            # Move source link to existing match
            warn "Moving key";
            $l10n_keys->search( { key => $key } )->update(
                {
                    l10n_source_id =>
                      $l10n_source_rs_new->l10n_source_id
                }
            );
        }
    }
    else {
        warn "No old source found";

        # Create new source link if required
        warn "Adding new source" unless $l10n_source_rs_new;
        $l10n_source_rs_new //=
          $self->result_source->schema->resultset('L10nSource')
          ->create( { group => $group, text => $updated_text } );
        warn "Adding key to source";
        #NOTE: Should this be an update_or_create (keyed on key + group)

        $l10n_source_rs_new->add_to_l10n_keys( { key => $key } );
    }
}

=head2 delete_l10n_source

    $self->delete_l10n_source($group, $key, $text)

Remove an entry from l10n_source

=cut

sub delete_l10n_source {
    my ($self, $group, $key) = @_;

    my $l10n_source_rs = $self->result_source->schema->resultset('L10nSource');
    $l10n_source_rs->search(
        {
            group => $group,
            key   => $key,
        }
    )->delete();
}

1;
