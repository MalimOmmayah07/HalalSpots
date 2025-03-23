(function () {
    'use strict'
  
    document.querySelector('#navbarSideCollapse').addEventListener('click', function () {
      document.querySelector('.offcanvas-collapse').classList.toggle('open')
    })
    
  
  $(".alert").fadeTo(2000, 2000).slideUp(1000, function(){
    $(".alert").slideUp(500);
  });

  var checks = document.getElementsByClassName('checkBox');
  var texts = document.getElementsByClassName('textBox');
  Array.from(checks).forEach((v,i) => v.addEventListener('change', function(){
    texts[i].disabled = !this.checked;
  }));

})()

$(document).ready(function() {
  var table = $('#serials').DataTable({
        lengthChange: false,
        paging: false,
        buttons: [
          {
            text: 'Export',
            title: 'Data export',
            extend: 'excel',
            className: 'btn-success',
              exportOptions: {
                  columns: ':visible'
              },
          },
          {
            text: 'Hide/Show',
            extend: 'colvis',
            className: 'btn-default',
          },
        ],
        columnDefs: [ {
          visible: false
      } ],
    } );
  table.buttons().container().appendTo( '#serials_wrapper .col-md-6:eq(0)' );
});



$(document).ready(function() {
  var table = $('#searchSerial').DataTable({
    paging: false,
    scrollY: '500px',
    scrollCollapse: true,
    columnDefs: [{
      target: 0,
      checkboxes: {
        selectRow: true
      }
    }],
    select: {
      style: 'multi',
      selector: '#mycheckboxes'
  }
  });
  table.searchBuilder.container().prependTo(table.table().container());
});

$(document).ready(function() {
  var table = $('#example').DataTable({
      searchBuilder: true,
      lengthChange: false,
      buttons: [
        {
          text: 'Export',
          title: 'Data export',
          extend: 'excel',
          className: 'btn-success',
            exportOptions: {
                columns: ':visible'
            },
        },
        {
          text: 'Hide/Show',
          extend: 'colvis',
          className: 'btn-default',
        },
      ],
      columnDefs: [ {
        visible: false
    } ]
  });
  table.buttons().container().appendTo( '#example_wrapper .col-md-6:eq(0)' );
});

$(document).ready(function() {
  var table = $('#exampleT').DataTable({
      searchBuilder: true,
      lengthChange: false,
      buttons: [
        {
          text: 'Export',
          title: 'Transaction History of Weapons Equipment',
          extend: 'excel',
          className: 'btn-success',
            exportOptions: {
                columns: ':visible'
            },
        },
        {
          text: 'Hide/Show',
          extend: 'colvis',
          className: 'btn-default',
        },
      ],
      columnDefs: [ {
        visible: false
    } ]
  });
  table.searchBuilder.container().prependTo(table.table().container());
  table.buttons().container().appendTo( '#exampleT_wrapper .col-md-6:eq(0)' );
});

$(document).ready(function() {
  var table = $('#exampleA').DataTable({
      searchBuilder: true,
      lengthChange: false,
      buttons: [
        {
          text: 'Export',
          title: 'Transaction History of Ammunitions',
          extend: 'excel',
          className: 'btn-success',
            exportOptions: {
                columns: ':visible'
            },
        },
        {
          text: 'Hide/Show',
          extend: 'colvis',
          className: 'btn-default',
        },
      ],
      columnDefs: [ {
        visible: false
    } ]
  });
  table.searchBuilder.container().prependTo(table.table().container());
  table.buttons().container().appendTo( '#exampleA_wrapper .col-md-6:eq(0)' );
});

const config = {
  search: false, // Toggle search feature. Default: false
  creatable: false, // Creatable selection. Default: false
  clearable: false, // Clearable selection. Default: false
}

// Validation
    // Enable dselect on all '.dselect'
    for (const el of document.querySelectorAll('.form-select')) {
      dselect(el)
    }
    // Example starter JavaScript for disabling form submissions if there are invalid fields
    void (function() {
      document.querySelectorAll('.needs-validation').forEach(form => {
        form.addEventListener('submit', event => {
          if (!form.checkValidity()) {
            event.preventDefault()
            event.stopPropagation()
          }
          form.classList.add('was-validated')
        })
      })
    })()
