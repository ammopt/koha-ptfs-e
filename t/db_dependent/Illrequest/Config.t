#!/usr/bin/perl

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

use Test::Exception;
use Test::More;
use Test::Warn;

# Some data structures that will be repeatedly referenced
my $defaults  = {
    api_key  => "564euie",
    api_auth => "unidaenudvnled",
};
my $application = {
    key  => "6546uedrun",
    auth => "edutrineadue",
};
# Simulate $from_xml
my $params = {
    application            => $application,
    backend                => "Dummy",
    configuration          => $defaults,
    reply_date             => "hide",
    staff_request_comments => "hide",
};
my $first_branch = {
    code => "test", api_key => "dphügnpgüffq", api_auth => "udrend"
};
my $second_branch = {
    code          => "second",
    api_key       => "eduirn",
    api_auth      => "eudtireand",
    request_limit => { count => "5" },
};

BEGIN {
    use_ok('Koha::Illrequest::Config');
}

my $config = Koha::Illrequest::Config->new(1); # with test_mode enabled.
isa_ok($config, 'Koha::Illrequest::Config');

# _load_configuration
is_deeply(
    Koha::Illrequest::Config::_load_configuration($params),
    {
        api_url         => 'http://apitest.bldss.bl.uk',
        backend         => 'Dummy',
        censorship      => {
            censor_notes_staff => 1,
            censor_reply_date => 1,
        },
        credentials     => {
            api_application => $application,
            api_keys        => { default => $defaults },
        },
        default_formats => {},
        digital_recipients => {},
        library_privileges => {},
        limits          => {},
        prefixes           => {},
        spec_file       => undef,
    },
    "Basic _load_configuration"
);

$params->{configuration}->{request_limit}->{count} = 10;
is_deeply(
    Koha::Illrequest::Config::_load_configuration($params),
    {
        api_url            => 'http://apitest.bldss.bl.uk',
        backend            => 'Dummy',
        censorship         => {
            censor_notes_staff => 1,
            censor_reply_date => 1,
        },
        credentials        => {
            api_application => $application,
            api_keys        => {
                default => {
                    api_auth => $defaults->{api_auth},
                    api_key  => $defaults->{api_key},
                }
            },
        },
        default_formats    => {},
        digital_recipients => {},
        library_privileges => {},
        limits             => { default => { count => 10 } },
        prefixes           => {},
        spec_file          => undef,
    },
    "Basic _load_configuration, with limit"
);

$params->{configuration}->{branch} = $first_branch;
is_deeply(
    Koha::Illrequest::Config::_load_configuration($params),
    {
        api_url         => 'http://apitest.bldss.bl.uk',
        backend         => 'Dummy',
        censorship      => {
            censor_notes_staff => 1,
            censor_reply_date => 1,
        },
        credentials     => {
            api_keys        => {
                default => {
                    api_key  => $defaults->{api_key},
                    api_auth => $defaults->{api_auth},
                },
                $first_branch->{code} => {
                    api_key  => $first_branch->{api_key},
                    api_auth => $first_branch->{api_auth},
                },
            },
            api_application => $application,
        },
        default_formats => {},
        digital_recipients => {},
        library_privileges => {},
        limits          => { default => { count => 10 } },
        prefixes           => {},
        spec_file       => undef,
    },
    "Single Branch _load_configuration"
);

$params->{configuration}->{branch} = [ $first_branch, $second_branch ];
is_deeply(
    Koha::Illrequest::Config::_load_configuration($params),
    {
        api_url         => 'http://apitest.bldss.bl.uk',
        credentials     => {
            api_keys        => {
                default => {
                    api_key  => $defaults->{api_key},
                    api_auth => $defaults->{api_auth},
                },
                $first_branch->{code} => {
                    api_key  => $first_branch->{api_key},
                    api_auth => $first_branch->{api_auth},
                },
                $second_branch->{code} => {
                    api_key  => $second_branch->{api_key},
                    api_auth => $second_branch->{api_auth},
                },
            },
            api_application => $application,
        },
        backend         => 'Dummy',
        censorship      => {
            censor_notes_staff => 1,
            censor_reply_date => 1,
        },
        default_formats => {},
        digital_recipients => {},
        library_privileges => {},
        limits          => {
            default => {count => 10 },
            branch  => {
                $second_branch->{code} => {count => 5 },
            },
        },
        prefixes           => {},
        spec_file       => undef,
    },
    "Multi Branch _load_configuration"
);

dies_ok { Koha::Illrequest::Config::_load_configuration($params, 1) }
    "Unmediated, missing config _load_configuration";

$params->{configuration}->{default_formats} = {
    format => 1, quality => 1, quantity => 1, service => 1, speed => 1
};
is_deeply(
    Koha::Illrequest::Config::_load_configuration($params, 1),
    {
        api_url         => 'http://apitest.bldss.bl.uk',
        backend         => 'Dummy',
        censorship      => {
            censor_notes_staff => 1,
            censor_reply_date => 1,
        },
        credentials     => {
            api_keys        => {
                default => {
                    api_key  => $defaults->{api_key},
                    api_auth => $defaults->{api_auth},
                },
                $first_branch->{code} => {
                    api_key  => $first_branch->{api_key},
                    api_auth => $first_branch->{api_auth},
                },
                $second_branch->{code} => {
                    api_key  => $second_branch->{api_key},
                    api_auth => $second_branch->{api_auth},
                },
            },
            api_application => $application,
        },
        default_formats => {
            default => {
                format => 1,
                quality => 1,
                quantity => 1,
                service => 1,
                speed => 1
            }
        },
        digital_recipients => {},
        library_privileges => {},
        limits          => {
            default => {count => 10 },
            branch  => {
                $second_branch->{code} => {count => 5 },
            },
        },
        prefixes           => {},
        spec_file       => undef,
    },
    "default_formats, default only _load_configuration"
);

# getDefaultFormats
dies_ok { $config->getLimitRules('wrongType') }
    "Faulty getDefaultFormats";

$config->{configuration} =
    Koha::Illrequest::Config::_load_configuration($params);
is_deeply(
    $config->getDefaultFormats('brw_cat'),
    {
        default => {
            format => 1,
            quality => 1,
            quantity => 1,
            service => 1,
            speed => 1
        }
    },
    "Default getDefaultFormats"
);

# getLimitRules
dies_ok { $config->getLimitRules('wrongType') }
    "Faulty getLimitRules";

$config->{configuration} =
    Koha::Illrequest::Config::_load_configuration($params);
is_deeply(
    $config->getLimitRules('branch'),
    {
        default => { count => 10 },
        second  => { count => 5 },
    },
    "second branch getLimitRules"
);

is_deeply(
    $config->getLimitRules('brw_cat'),
    {
        default => { count => 10 },
    },
    "empty brw_cat getLimitRules"
);

# getCredentials
$params = {
    application            => $application,
    backend                => 'Dummy',
    configuration          => {},
    reply_date             => "hide",
    staff_request_comments => "hide",
};
$config->{configuration} =
    Koha::Illrequest::Config::_load_configuration($params);
is_deeply(
    $config->getCredentials,
    {
        api_key              => 0,
        api_key_auth         => 0,
        api_application      => $application->{key},
        api_application_auth => $application->{auth},
    },
    "getCredentials, no creds, just App."
);

$params->{configuration} = $defaults;
$config->{configuration} =
    Koha::Illrequest::Config::_load_configuration($params),
is_deeply(
    $config->getCredentials,
    {
        api_key              => $defaults->{api_key},
        api_key_auth         => $defaults->{api_auth},
        api_application      => $application->{key},
        api_application_auth => $application->{auth},
    },
    "getCredentials, default creds & App."
);

$params->{configuration}->{branch} = $first_branch;
$config->{configuration} =
    Koha::Illrequest::Config::_load_configuration($params),
is_deeply(
    $config->getCredentials($first_branch->{code}),
    {
        api_key              => $first_branch->{api_key},
        api_key_auth         => $first_branch->{api_auth},
        api_application      => $application->{key},
        api_application_auth => $application->{auth},
    },
    "getCredentials, $first_branch->{code} creds & App."
);

is_deeply(
    $config->getCredentials("random"),
    {
        api_key              => $defaults->{api_key},
        api_key_auth         => $defaults->{api_auth},
        api_application      => $application->{key},
        api_application_auth => $application->{auth},
    },
    "getCredentials, fallback creds & app."
);

done_testing;
