Ophal.extend('migrate', function($) {

  function importer_loop(params) {
    var object_id = params.list[params.pos];
    if (object_id) {
      $('#migrate_' + params.id + ' .current').html(params.source + ' #' + object_id);
      Ophal.post({
        url: 'migrate',
        data: {id: params.id, source: params.source, action: 'import', object_id: object_id},
        success: function(data) {
          if (data.imported) {
            params.pos++;
            params.count++;
            Ophal.progress('#migrate_' + params.id, Math.round(params.count/params.total*100));
            if (params.list[params.pos]) {
              importer_loop(params);
            }
            else {
              params.complete(params.count);
            }
          }
          else {
            alert('Error importing: ' + params.source + ' #' + object_id);
          }
        },
        error: function() {
          alert('Unexpected error! Can not import an object.');
        }
      });
    }
  }

  function fetcher_loop(params) {
    Ophal.post({
      url: 'migrate',
      data: {id: params.id, source: params.source, action: 'list', last_id: params.last_id},
      success: function(data) {
        /* Import objects */
        if (data.list) {
          var list = data.list;
          var count = 0;
          if (params.count) {
            count = params.count;
          }
          importer_loop({
            id: params.id,
            source: params.source,
            list: list,
            pos: 0,
            count: count,
            total: params.total,
            complete: function(count) {
              params.last_id = list[99];
              params.count = count;
              if (list[99]) {
                fetcher_loop(params);
              }
              else {
                params.complete();
              }
            }
          });
        }
      },
      error: function() {
        alert('Unexpected error! Can not list current migration page.');
      }
    });
  }

  Ophal.migrate = {
    start: function(id) {
      var config = Ophal.settings.migrate[id]
      var count, pages, last_id

      /* Count objects */
      Ophal.post({
        url: 'migrate',
        data: {id: id, source: config.source, action: 'count'},
        success: function(data) {
          if (data.count) {
            count = data.count
            $('#migrate_' + id + ' .total').html(count);

            /* Fetch objects lists & migrate */
            fetcher_loop({
              id: id,
              source: config.source,
              total: count,
              complete: function() {

                /* Import completed */
                alert('Import completed!');
              }
            });
          }
          else {
            alert('Can not count objects.');
          }
        },
        error: function() {
          alert('Unexpected error! Please try again later.');
        }
      });
    }
  }
});