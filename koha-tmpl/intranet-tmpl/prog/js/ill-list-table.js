$(document).ready(function() {

    // Illview Datatable setup

    var table;

    // Filters that are active
    var activeFilters = {};

    $('#illfilter_dateplaced_start, #illfilter_dateplaced_end, #illfilter_datemodified_start, #illfilter_datemodified_end').datepicker(
        'option', 'dateFormat', dateFormat
    );

    // Fields we need to expand (flatten)
    var expand = [
        'metadata',
        'patron',
        'library'
    ];

    // Expanded fields
    // This is auto populated
    var expanded = {};

    // Filterable columns
    var filterable = {
        status: {
            prep: function(tableData, oData) {
                var uniques = {};
                tableData.forEach(function(row) {
                    var resolvedName;
                    if (row.status_alias) {
                        resolvedName = row.status_alias.authorised_value;
                    } else {
                        resolvedName = getStatusName(
                            oData[0].capabilities[row.status].name
                        );
                    }
                    uniques[resolvedName] = 1
                });
                Object.keys(uniques).sort().forEach(function(unique) {
                    $('#illfilter_status').append(
                        '<option value="' + unique  +
                        '">' + unique +  '</option>'
                    );
                });
            },
            listener: function() {
                var me = 'status';
                $('#illfilter_status').change(function() {
                    var sel = $('#illfilter_status option:selected').val();
                    if (sel && sel.length > 0) {
                        activeFilters[me] = function() {
                            table.column(7).search(sel);
                        }
                    } else {
                        if (activeFilters.hasOwnProperty(me)) {
                            delete activeFilters[me];
                        }
                    }
                });
            },
            clear: function() {
                $('#illfilter_status').val('');
            }
        },
        pickupBranch: {
            prep: function(tableData, oData) {
                var uniques = {};
                tableData.forEach(function(row) {
                    uniques[row.library_branchname] = 1
                });
                Object.keys(uniques).sort().forEach(function(unique) {
                    $('#illfilter_branchname').append(
                        '<option value="' + unique  +
                        '">' + unique +  '</option>'
                    );
                });
            },
            listener: function() {
                var me = 'pickupBranch';
                $('#illfilter_branchname').change(function() {
                    var sel = $('#illfilter_branchname option:selected').val();
                    if (sel && sel.length > 0) {
                        activeFilters[me] = function() {
                            table.column(6).search(sel);
                        }
                    } else {
                        if (activeFilters.hasOwnProperty(me)) {
                            delete activeFilters[me];
                        }
                    }
                });
            },
            clear: function() {
                $('#illfilter_branchname').val('');
            }
        },
        barcode: {
            listener: function() {
                var me = 'barcode';
                $('#illfilter_barcode').change(function() {
                    var val = $('#illfilter_barcode').val();
                    if (val && val.length > 0) {
                        activeFilters[me] = function() {
                            table.column(4).search(val);
                        }
                    } else {
                        if (activeFilters.hasOwnProperty(me)) {
                            delete activeFilters[me];
                        }
                    }
                });
            },
            clear: function() {
                $('#illfilter_barcode').val('');
            }
        },
        dateModified: {
            clear: function() {
                $('#illfilter_datemodified_start, #illfilter_datemodified_end').val('');
            }
        },
        datePlaced: {
            clear: function() {
                $('#illfilter_dateplaced_start, #illfilter_dateplaced_end').val('');
            }
        }
    };

    // Expand any fields we're expanding
    var expandExpand = function(row) {
        expand.forEach(function(thisExpand) {
            if (row.hasOwnProperty(thisExpand)) {
                if (!expanded.hasOwnProperty(thisExpand)) {
                    expanded[thisExpand] = [];
                }
                var expandObj = row[thisExpand];
                Object.keys(expandObj).forEach(
                    function(thisExpandCol) {
                        var expColName = thisExpand + '_' + thisExpandCol.replace(/\s/g,'_');
                        // Keep a list of fields that have been expanded
                        // so we can create toggle links for them
                        if (expanded[thisExpand].indexOf(expColName) == -1) {
                            expanded[thisExpand].push(expColName);
                        }
                        expandObj[expColName] =
                            expandObj[thisExpandCol];
                        delete expandObj[thisExpandCol];
                    }
                );
                $.extend(true, row, expandObj);
                delete row[thisExpand];
            }
        });
    };

    // Strip the expand prefix if it exists, we do this for display
    var stripPrefix = function(value) {
        expand.forEach(function(thisExpand) {
            var regex = new RegExp(thisExpand + '_', 'g');
            value = value.replace(regex, '');
        });
        return value;
    };

    // Our 'render' function for patron name
    var createPatronName = function(data, type, row) {
        return '<a title="' + _("View borrower details") + '" ' +
            'href="/cgi-bin/koha/members/moremember.pl?' +
            'borrowernumber='+row.borrowernumber+'">' +
            row.patron_firstname + ' ' + row.patron_surname +
            '</a>';
    };

    // Render function for type
    var createType = function(data, type, row) {
        if (!row.hasOwnProperty('metadata_Type') || !row.metadata_Type) {
            if (row.hasOwnProperty('medium') && row.medium) {
                row.metadata_Type = row.medium;
            } else {
                row.metadata_Type = null;
            }
        }
        return row.metadata_Type;
    };
    

    // Our 'render' function for patron userid
    var createPatronUserID = function(data, type, row) {
        return '<a title="' + _("View borrower details") + '" ' +
            'href="/cgi-bin/koha/members/moremember.pl?' +
            'borrowernumber='+row.borrowernumber+'">' +
            row.patron_userid +
            '</a>';
    };

    // Our 'render' function for biblio_id
    var createBiblioLink = function(data, type, row) {
        return '<a title="' + _("View biblio details") + '" ' +
            'href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=' +
            row.biblio_id + '">' +
            row.biblio_id +
            '</a>';
    };

    // Our 'render' function for the library name
    var createLibrary = function(data, type, row) {
        return row.library.branchname;
    };

    // Render function for request ID
    var createRequestId = function(data, type, row) {
        return row.id_prefix + row.illrequest_id;
    };

    // Render function for title
    var createTitle = function(data, type, row) {
        return row.hasOwnProperty('metadata_container_title') ?
            row.metadata_container_title :
            row.metadata_title;
    };

    // Render function for article title
    var createArticleTitle = function(data, type, row) {
        return row.hasOwnProperty('metadata_container_title') ?
            row.metadata_title :
            '';
    };

    // Render function for request status
    var createStatus = function(data, type, row, meta) {
        if (row.status_alias) {
            return row.status_alias.authorised_value;
        } else {
            var origData = meta.settings.oInit.originalData;
            if (origData.length > 0) {
                var status_name = meta.settings.oInit.originalData[0]
                    .capabilities[row.status].name;
                return getStatusName(status_name);
            } else {
                return '';
            }
        }
    };

    var getStatusName = function(origName) {
        switch( origName ) {
            case "New request":
                return _("New request");
            case "Requested":
                return _("Requested");
            case "Requested from partners":
                return _("Requested from partners");
            case "Request reverted":
                return _("Request reverted");
            case "Queued request":
                return _("Queued request");
            case "Cancellation requested":
                return _("Cancellation requested");
            case "Completed":
                return _("Completed");
            case "Delete request":
                return _("Delete request");
            default:
                return status_name;
        }
    };

    // Render function for additional status
    var createAdditional = function(data, type, row) {
        return (
            row.hasOwnProperty('requested_partners') &&
            row.requested_partners &&
            row.requested_partners.length > 0
        ) ?
            "Requested from:<br>" +
            row.requested_partners.replace('; ','<br>') :
            '';
    };

    // Render function for creating a row's action link
    var createActionLink = function(data, type, row) {
        return '<a class="btn btn-default btn-sm" ' +
            'href="/cgi-bin/koha/ill/ill-requests.pl?' +
            'method=illview&amp;illrequest_id=' +
            row.illrequest_id +
            '">' + _("Manage request") + '</a>';
    };

    // Columns that require special treatment
    var specialCols = {
        action: {
            func: createActionLink
        },
        borrowernumber: {
            func: createPatronName
        },
        borroweruserid: {
            func: createPatronUserID
        },
        illrequest_id: {
            func: createRequestId
        },
        status: {
            func: createStatus
        },
        additional_status: {
            func: createAdditional
        },
        biblio_id: {
            func: createBiblioLink
        },
        library: {
            func: createLibrary
        },
        metadata_title: {
            func: createTitle
        },
        metadata_article_title: {
            func: createArticleTitle
        },
        metadata_Medium: {
            func: createType
        },
        metadata_Type: {
            func: createType
        }
    };

    // Filter partner list
    $('#partner_filter').keyup(function() {
        var needle = $('#partner_filter').val();
        $('#partners > option').each(function() {
            var regex = new RegExp(needle, 'i');
            if (
                needle.length == 0 ||
                $(this).is(':selected') ||
                $(this).text().match(regex)
            ) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });

    // Display the modal containing request supplier metadata
    $('#ill-request-display-log').on('click', function(e) {
        e.preventDefault();
        $('#requestLog').modal({show:true});
    });

    // Display the modal containing request supplier metadata
    $('#ill-request-display-metadata').on('click', function(e) {
        e.preventDefault();
        $('#dataPreview').modal({show:true});
    });

    // Get our data from the API and process it prior to passing
    // it to datatables
    var url = '/api/v1/illrequests?embed=requested_partners,metadata,patron,capabilities,library,status_alias';
    if (typeof prefilters != 'undefined' && prefilters.length > 0) {
        url += '&' + prefilters;
    }
    var ajax = $.ajax(url).done(function() {
            var data = JSON.parse(ajax.responseText);
            // Make a copy, we'll be removing columns next and need
            // to be able to refer to data that has been removed
            var dataCopy = $.extend(true, [], data);
            // Expand columns that need it and create an array
            // of all column names
            $.each(dataCopy, function(k, row) {
                expandExpand(row);
            });

            // Assemble an array of column definitions for passing
            // to datatables
            var colData = [];
            columns_settings.forEach(function(thisCol) {
                var colName = thisCol.columnname;
                // Create the base column object
                var colObj = $.extend({}, thisCol);
                colObj.name = colName;
                colObj.className = colName;
                colObj.defaultContent = ''
                // We may need to process the data going in this
                // column, so do it if necessary
                if (
                    specialCols.hasOwnProperty(colName) &&
                    specialCols[colName].hasOwnProperty('func')
                ) {
                    colObj.render = specialCols[colName].func;
                } else {
                    colObj.data = colName;
                }
				// Make sure properties that aren't present in the API
				// response are populated with null to avoid Datatables
				// choking on their absence
				dataCopy.forEach(function(thisData) {
					if (!thisData.hasOwnProperty(colName)) {
						thisData[colName] = null;
					}
				});
                colData.push(colObj);
            });

            // Initialise the datatable
			table = KohaTable("#ill-requests", {
                'aoColumnDefs': [
                    { // Last column shouldn't be sortable or searchable
                        'aTargets': [ 'actions' ],
                        'bSortable': false,
                        'bSearchable': false
                    },
                    { // When sorting 'placed', we want to use the
                        // unformatted column
                        'aTargets': [ 'placed_formatted'],
                        'iDataSort': 14
                    },
                    { // When sorting 'updated', we want to use the
                        // unformatted column
                        'aTargets': [ 'updated_formatted'],
                        'iDataSort': 17
                    }
                ],
                'aaSorting': [[17, 'desc' ]], // Default sort, updated descending
                'processing': true, // Display a message when manipulating
                'iDisplayLength': 10, // 10 results per page
                'sPaginationType': "full_numbers", // Pagination display
                'deferRender': true, // Improve performance on big datasets
                'data': dataCopy,
                'columns': colData,
                'originalData': data, // Enable render functions to access
                                        // our original data
                'initComplete': function() {
                    // Prepare any filter elements that need it
                    for (var el in filterable) {
                        if (filterable.hasOwnProperty(el)) {
                            if (filterable[el].hasOwnProperty('prep')) {
                                filterable[el].prep(dataCopy, data);
                            }
                            if (filterable[el].hasOwnProperty('listener')) {
                                filterable[el].listener();
                            }
                        }
                    }
                }
            }, columns_settings);

            // Custom date range filtering
            $.fn.dataTable.ext.search.push(function(settings, data, dataIndex) {
                var placedStart = $('#illfilter_dateplaced_start').datepicker('getDate');
                var placedEnd = $('#illfilter_dateplaced_end').datepicker('getDate');
                var modifiedStart = $('#illfilter_datemodified_start').datepicker('getDate');
                var modifiedEnd = $('#illfilter_datemodified_end').datepicker('getDate');
                var rowPlaced = data[14] ? new Date(data[14]) : null;
                var rowModified = data[17] ? new Date(data[17]) : null;
                var placedPassed = true;
                var modifiedPassed = true;
                if (placedStart && rowPlaced && rowPlaced < placedStart) {
                    placedPassed = false
                };
                if (placedEnd && rowPlaced && rowPlaced > placedEnd) {
                    placedPassed = false;
                }
                if (modifiedStart && rowModified && rowModified < modifiedStart) {
                    modifiedPassed = false
                };
                if (modifiedEnd && rowModified && rowModified > modifiedEnd) {
                    modifiedPassed = false;
                }

                return placedPassed && modifiedPassed;

            });
        }
    );

    var clearSearch = function() {
        table.search('').columns().search('');
        activeFilters = {};
        for (var filter in filterable) {
            if (
                filterable.hasOwnProperty(filter) &&
                filterable[filter].hasOwnProperty('clear')
            ) {
                filterable[filter].clear();
            }
        }
        table.draw();
    };

    // Apply any search filters, or clear any previous
    // ones
    $('#illfilter_form').submit(function(event) {
        event.preventDefault();
        table.search('').columns().search('');
        for (var active in activeFilters) {
            if (activeFilters.hasOwnProperty(active)) {
                activeFilters[active]();
            }
        }
        table.draw();
    });

    // Clear all filters
    $('#clear_search').click(function() {
        clearSearch();
    });

});
