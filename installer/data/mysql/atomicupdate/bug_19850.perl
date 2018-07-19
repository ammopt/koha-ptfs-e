$DBversion = 'XXX';    # will be replaced by the RM
if ( CheckVersion($DBversion) ) {
    $dbh->do( "
        CREATE TABLE IF NOT EXISTS aqinvoice_lines(
            id int(11) NOT NULL AUTO_INCREMENT,
            aqinvoices_invoiceid int(11) NOT NULL,
            aqorders_ordernumber int(11) NOT NULL,
            aqbudgets_budgetid int(11),
            description mediumtext DEFAULT NULL,
            quantity int(11) NOT NULL DEFAULT 1,
            list_price decimal( 28, 6 ),
            discount_rate decimal( 28, 6 ),
            discount_amount decimal( 28, 6 ),
            pre_tax_price decimal( 28, 6 ),
            tax_rate decimal( 28, 6 ),
            tax_amount decimal( 28, 6 ),
            total_price decimal( 28, 6 ),
            PRIMARY KEY(id),
            CONSTRAINT aqinvoice_lines_fk_invoiceid FOREIGN KEY(aqinvoices_invoiceid)
              REFERENCES aqinvoices(invoiceid) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT aqinvoice_lines_fk_orderid FOREIGN KEY(aqorders_ordernumber)
              REFERENCES aqorders(ordernumber) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT aqinvoice_lines_fk_budgetid FOREIGN KEY(aqbudgets_budgetid)
              REFERENCES aqbudgets(budget_id) ON DELETE SET NULL ON UPDATE CASCADE
          )
    " );

    # Always end with this (adjust the bug info)
    SetVersion($DBversion);
    print
"Upgrade to $DBversion done (Bug 19850 - Add aqinvoice_lines table to allow breakdown of invoices at the aqorder line level)\n";
}
