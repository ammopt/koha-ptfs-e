use Modern::Perl;

return {
    bug_number => "BUG_NUMBER",
    description => "Some tables for ERM",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};

        $dbh->do(q{
            INSERT IGNORE INTO systempreferences (variable,value,explanation,options,type)
            VALUES ('ERMModule', '0', NULL, 'Enable the E-Resource management module', 'YesNo');
        });

        $dbh->do(q{
            INSERT IGNORE INTO userflags (bit, flag, flagdesc, defaulton)
            VALUES (28, 'erm', 'Manage electronic resources', 0)
        });

        unless ( TableExists('erm_agreements') ) {
            $dbh->do(q{
                CREATE TABLE `erm_agreements` (
                    `agreement_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
                    `vendor_id` INT(11) DEFAULT NULL COMMENT 'foreign key to aqbooksellers',
                    `name` VARCHAR(255) NOT NULL COMMENT 'name of the agreement',
                    `description` LONGTEXT DEFAULT NULL COMMENT 'description of the agreement',
                    `status` VARCHAR(80) NOT NULL COMMENT 'current status of the agreement',
                    `closure_reason` VARCHAR(80) DEFAULT NULL COMMENT 'reason of the closure',
                    `is_perpetual` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'is the agreement perpetual',
                    `renewal_priority` VARCHAR(80) DEFAULT NULL COMMENT 'priority of the renewal',
                    `license_info` VARCHAR(80) DEFAULT NULL COMMENT 'info about the license',
                    CONSTRAINT `erm_agreements_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `aqbooksellers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
                    PRIMARY KEY(`agreement_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }

        $dbh->do(q{
            INSERT IGNORE INTO authorised_value_categories (category_name, is_system)
            VALUES
                ('ERM_AGREEMENT_STATUS', 1),
                ('ERM_AGREEMENT_CLOSURE_REASON', 1),
                ('ERM_AGREEMENT_RENEWAL_PRIORITY', 1)
            });
        $dbh->do(q{
            INSERT IGNORE INTO authorised_values (category, authorised_value, lib)
            VALUES
                ('ERM_AGREEMENT_STATUS', 'active', 'Active'),
                ('ERM_AGREEMENT_STATUS', 'in_negotiation', 'In negotiation'),
                ('ERM_AGREEMENT_STATUS', 'closed', 'Closed'),
                ('ERM_AGREEMENT_CLOSURE_REASON', 'expired', 'Expired'),
                ('ERM_AGREEMENT_CLOSURE_REASON', 'cancelled', 'Cancelled'),
                ('ERM_AGREEMENT_RENEWAL_PRIORITY', 'for_review', 'For review'),
                ('ERM_AGREEMENT_RENEWAL_PRIORITY', 'renew', 'Renew'),
                ('ERM_AGREEMENT_RENEWAL_PRIORITY', 'cancel', 'Cancel')
        });

        unless ( TableExists('erm_agreement_periods') ) {
            $dbh->do(q{
                CREATE TABLE `erm_agreement_periods` (
                    `agreement_period_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
                    `agreement_id` INT(11) NOT NULL COMMENT 'link to the agreement',
                    `started_on` DATE NOT NULL COMMENT 'start of the agreement period',
                    `ended_on` DATE COMMENT 'end of the agreement period',
                    `cancellation_deadline` DATE DEFAULT NULL COMMENT 'Deadline for the cancellation',
                    `notes` mediumtext DEFAULT NULL COMMENT 'notes about this period',
                    CONSTRAINT `erm_agreement_periods_ibfk_1` FOREIGN KEY (`agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    PRIMARY KEY(`agreement_period_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }

        unless ( TableExists('erm_agreement_user_roles') ) {
            $dbh->do(q{
                CREATE TABLE `erm_agreement_user_roles` (
                    `agreement_id` INT(11) NOT NULL COMMENT 'link to the agreement',
                    `user_id` INT(11) NOT NULL COMMENT 'link to the user',
                    `role` VARCHAR(80) NOT NULL COMMENT 'role of the user',
                    CONSTRAINT `erm_agreement_users_ibfk_1` FOREIGN KEY (`agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    CONSTRAINT `erm_agreement_users_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `borrowers` (`borrowernumber`) ON DELETE CASCADE ON UPDATE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }
        $dbh->do(q{
            INSERT IGNORE INTO authorised_value_categories (category_name, is_system)
            VALUES
                ('ERM_AGREEMENT_USER_ROLES', 1)
        });
        $dbh->do(q{
            INSERT IGNORE INTO authorised_values (category, authorised_value, lib)
            VALUES
                ('ERM_AGREEMENT_USER_ROLES', 'librarian', 'ERM librarian'),
                ('ERM_AGREEMENT_USER_ROLES', 'subject_specialist', 'Subject specialist')
        });

        unless ( TableExists('erm_licenses') ) {
            $dbh->do(q{
                CREATE TABLE `erm_licenses` (
                    `license_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
                    `name` VARCHAR(255) NOT NULL COMMENT 'name of the license',
                    `description` LONGTEXT DEFAULT NULL COMMENT 'description of the license',
                    `type` VARCHAR(80) NOT NULL COMMENT 'type of the license',
                    `status` VARCHAR(80) NOT NULL COMMENT 'current status of the license',
                    `started_on` DATE COMMENT 'start of the license',
                    `ended_on` DATE COMMENT 'end of the license',
                    PRIMARY KEY(`license_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }
        unless ( TableExists('erm_agreement_licenses') ) {
            $dbh->do(q{
                CREATE TABLE `erm_agreement_licenses` (
                    `agreement_license_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
                    `agreement_id` INT(11) NOT NULL COMMENT 'link to the agreement',
                    `license_id` INT(11) NOT NULL COMMENT 'link to the license',
                    `status` VARCHAR(80) NOT NULL COMMENT 'current status of the license',
                    `physical_location` VARCHAR(80) DEFAULT NULL COMMENT 'physical location of the license',
                    `notes` mediumtext DEFAULT NULL COMMENT 'notes about this license',
                    `uri` varchar(255) DEFAULT NULL COMMENT 'URI of the license',
                    CONSTRAINT `erm_licenses_ibfk_1` FOREIGN KEY (`agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    CONSTRAINT `erm_licenses_ibfk_2` FOREIGN KEY (`license_id`) REFERENCES `erm_licenses` (`license_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    PRIMARY KEY(`agreement_license_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }
        $dbh->do(q{
            INSERT IGNORE INTO authorised_value_categories (category_name, is_system)
            VALUES
                ('ERM_LICENSE_TYPE', 1),
                ('ERM_LICENSE_STATUS', 1),
                ('ERM_AGREEMENT_LICENSE_STATUS', 1),
                ('ERM_AGREEMENT_LICENSE_LOCATION', 1);
        });

        $dbh->do(q{
            INSERT IGNORE INTO authorised_values (category, authorised_value, lib)
            VALUES
                ('ERM_LICENSE_TYPE', 'local', 'Local'),
                ('ERM_LICENSE_TYPE', 'consortial', 'Consortial'),
                ('ERM_LICENSE_TYPE', 'national', 'National'),
                ('ERM_LICENSE_TYPE', 'alliance', 'Alliance'),
                ('ERM_LICENSE_STATUS', 'in_negotiation', 'In negociation'),
                ('ERM_LICENSE_STATUS', 'not_yet_active', 'Not yet active'),
                ('ERM_LICENSE_STATUS', 'active', 'Active'),
                ('ERM_LICENSE_STATUS', 'rejected', 'Rejected'),
                ('ERM_LICENSE_STATUS', 'expired', 'Expired'),
                ('ERM_AGREEMENT_LICENSE_STATUS', 'controlling', 'Controlling'),
                ('ERM_AGREEMENT_LICENSE_STATUS', 'future', 'Future'),
                ('ERM_AGREEMENT_LICENSE_STATUS', 'history', 'Historic'),
                ('ERM_AGREEMENT_LICENSE_LOCATION', 'filing_cabinet', 'Filing cabinet'),
                ('ERM_AGREEMENT_LICENSE_LOCATION', 'cupboard', 'Cupboard');
        });

        unless ( TableExists('erm_agreement_relationships') ) {
            $dbh->do(q{
                CREATE TABLE `erm_agreement_relationships` (
                    `agreement_id` INT(11) NOT NULL COMMENT 'link to the agreement',
                    `related_agreement_id` INT(11) NOT NULL COMMENT 'link to the related agreement',
                    `relationship` ENUM('supersedes', 'is-superseded-by', 'provides_post-cancellation_access_for', 'has-post-cancellation-access-in', 'tracks_demand-driven_acquisitions_for', 'has-demand-driven-acquisitions-in', 'has_backfile_in', 'has_frontfile_in', 'related_to') NOT NULL COMMENT 'relationship between the two agreements',
                    `notes` mediumtext DEFAULT NULL COMMENT 'notes about this relationship',
                    CONSTRAINT `erm_agreement_relationships_ibfk_1` FOREIGN KEY (`agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    CONSTRAINT `erm_agreement_relationships_ibfk_2` FOREIGN KEY (`related_agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                    PRIMARY KEY(`agreement_id`, `related_agreement_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            });
        }
    },
};
