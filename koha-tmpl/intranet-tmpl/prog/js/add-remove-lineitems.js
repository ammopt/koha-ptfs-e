// Addition and removal of line items
function addRemoveLineitems(t) {
    var removeRow = function(tr) {
        var row = t.api().row(tr);
        row.child.hide();
        tr.removeClass('shown');
        $(tr).find('.hide-order-details').hide();
        $(tr).find('.show-order-details').show();
    };
    $('.hide-order-details').hide();
    $('.show-order-details').on('click', function(e) {
        e.preventDefault();
        // First remove any existing details rows
        // being displayed
        window.killReact();
        $('tr.shown').each(function() {
            removeRow($(this));
        });
        // Now display the requested details
        var tr = $(this).closest('tr');
        var row = t.api().row(tr);
        row.child('<div id="react-orderreceive-lineitems"></div>').show();
        tr.addClass('shown');
        $(tr).find('.show-order-details').hide();
        $(tr).find('.hide-order-details').show();
        window.initReact($(this).data('invoiceid'), $(this).data('ordernumber'), true);
    });
    $('.hide-order-details').on('click', function(e) {
        e.preventDefault();
        window.killReact();
        removeRow($(this).closest('tr'));
    });
}
