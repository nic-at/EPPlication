(function( JSONEditor,  undefined ) {
    'use strict';

    var modal;
    var dialog;

    function setup_modal() {
        modal  = $('<div class="modal" style="display: none;" aria-hidden="true"></div>');
        dialog = $('<div class="modal-dialog"></div>');
        modal.append(dialog);
        modal.on('hidden.bs.modal', function () { modal.remove(); })
        $('body').append(modal);
        modal.modal('show');
    }

    function drop_content() {
        if ( dialog.children().length > 0 ) {
            dialog.children().last().remove();
        }

        if ( dialog.children().length > 0 ) {
            dialog.children().last().show();
        }
        else {
            modal.modal('hide');
        }
    }

    function show_dialog(content) {
        dialog.children().hide();
        dialog.append(content);
    }

    function isArray(val) {
        return Object.prototype.toString.call(val) === '[object Array]'
            ? true
            : false;
    }
    function isHash(val) {
        return Object.prototype.toString.call(val) === '[object Object]'
            ? true
            : false;
    }

    function process(input) {
        var val = input.val();
        if ( val === '' ) {
            new_dialog_mode(input);
        }
        else {
            try {
                var val_json = JSON.parse(val);
                if (isArray(val_json)) {
                    new_dialog('ARRAY', input, val_json);
                }
                else if (isHash(val_json))  {
                    new_dialog('HASH', input, val_json);
                }
                else {
                    throw('Input is not ARRAY or HASH');
                }
            }
            catch(e) { console.log(e); new_dialog_error('Invalid input: ' + val); }
        }
    }

    function get_header(title) {
        title = typeof title === 'string'
                    ? 'JSONEditor (' + title + ')'
                    : 'JSONEditor';
        return '<div class="modal-header">'
             + '  <button type="button" class="close" data-dismiss="modal" aria-label="Close">'
             + '    <span aria-hidden="true">&times;</span>'
             + '  </button>'
             + '  <h4 class="modal-title">' + title + '</h4>'
             + '</div>';
    }

    function new_dialog_error(msg) {
        var content = $('<div class="modal-content"></div>');
        var header = get_header('Error');
        var body   = $('<div class="modal-body"></div>');
        var footer = $('<div class="modal-footer"></div>');
        body.append(msg);
        add_btn_ok(footer);
        content.append(header, body, footer);
        show_dialog(content);
    }

    function new_dialog_mode(input) {
        var content = $(''
            + '<div class="modal-content">'
            + get_header()
            + '  <div class="modal-body">'
            + '    <div class="text-center">'
            + '      <a id="mode-array" class="btn btn-lg btn-primary">ARRAY</a>'
            + '      <a id="mode-hash" class="btn btn-lg btn-primary">HASH</a>'
            + '    </div>'
            + '  </div>'
            + '  <div class="modal-footer">'
            + '  </div>'
            + '</div>');
        content.find('#mode-array').click(function() {
            new_dialog('ARRAY', input);
            content.remove();
        });
        content.find('#mode-hash').click(function() {
            new_dialog('HASH', input);
            content.remove();
        });
        show_dialog(content);
    }

    function new_dialog(mode, input, value) {
        var content = $('<div class="modal-content"></div>');
        var header = get_header(mode);
        var body   = $('<div class="modal-body"></div>');
        var footer = $('<div class="modal-footer"></div>');
        var form   = $('<form class="form-horizontal">');
        add_btn_new_element(mode, form);
        add_elements(mode, form, value);
        body.append(form);
        add_btn_back(footer);
        add_save_btn(mode, form, footer, input);
        content.append(header, body, footer);
        show_dialog(content);
    }

    function add_elements(mode, form, value) {
        if (mode === 'ARRAY') {
            value = typeof value === 'undefined' ? [''] : value;
            $.each(value, function(index, val) {
                val = inflate_value(val);
                var form_group  = $('<div class="form-group"></div>');
                var col1        = $('<div class="col-lg-12"></div>');
                var input       = $('<input class="form-control" type="text">').val(val);
                form.append(form_group);
                form_group.append(col1);
                col1.append(input);
                add_btn_remove(input);
                add_btn_edit_json( input );
            });
            return form;
        }
        else if (mode === 'HASH') {
            value = typeof value === 'undefined' ? {'':''} : value;
            $.each(value, function(key, val) {
                val = inflate_value(val);
                var form_group  = $('<div class="form-group"></div>');
                var col1        = $('<div class="col-lg-3"></div>');
                var input_key   = $('<input class="form-control" type="text">').val(key);
                var col2        = $('<div class="col-lg-9"></div>');
                var input_value = $('<input class="form-control" type="text">').val(val);
                form.append(form_group);
                form_group.append(col1);
                form_group.append(col2);
                col1.append(input_key);
                col2.append(input_value);
                add_btn_remove(input_value);
                add_btn_edit_json( input_value );
            });
            return form;
        }
    }

    function add_btn_ok(footer) {
        var btn = $('<a id="btn-json-ok" class="btn btn-primary">Ok</a>');
        btn.click( function() { drop_content(); } );
        footer.append(btn);
    }
    function add_btn_back(footer) {
        var btn = $('<a id="btn-json-back" class="btn btn-default">Back</a>');
        btn.click( function() { drop_content(); } );
        footer.append(btn);
    }

    function add_save_btn(mode, form, footer, input) {
        var btn = $('<a id="btn-json-save" class="btn btn-primary">Save</a>');
        btn.click(
            function() {
                if (mode === 'ARRAY') {
                    var elements = form.find('.form-group input[type="text"]');
                    var values = [];
                    elements.each(function(){
                        values.push( deflate_value($(this).val()) );
                    });
                    var result = '[' + values.join(',') + ']';
                    input.val(result);
                    drop_content();
                }
                else if (mode === 'HASH') {
                    var elements = form.find('.form-group:has(input[type="text"])');
                    var result = [];
                    elements.each(function(index){
                        var kv  = $(this).find('input[type="text"]');
                        var key = kv[0];
                        var val = kv[1];
                        result.push(
                            JSON.stringify($(key).val())
                            + ':'
                            + deflate_value( $(val).val() )
                            );
                    });
                    input.val('{' + result.join(',') + '}');
                    drop_content();
                }
            }
        );
        footer.append(btn);
    }

    function add_btn_remove(target) {
        var btn = $('<span class="jsoneditor jsoneditor-remove glyphicon glyphicon-remove" title="remove element"></span>');
        btn.click(function(event){
            target.closest('.form-group').remove();
        });
        target.after(btn);
    }

    // if value is Array or Hash do not surround with quotes
    function deflate_value(val) {
        try {
            // Array or Hash
            var result = JSON.parse(val);
            if ( isArray(result) || isHash(result) ) {
                return val;
            }
        } catch (e) { /* do nothing */ }
        return JSON.stringify(val);
    }

    function inflate_value(val) {
        if (typeof(val) !== 'string') {
            val = JSON.stringify(val);
        }
        return val;
    }

    function add_btn_new_element(mode, target) {
        target.append( '<div class="form-group">'
                     + '  <div class="col-lg-12">'
                     + '    <a class="btn btn-default"><i class="glyphicon glyphicon-plus"></i></a>'
                     + '  </div>'
                     + '</div>');
        var btn_add_element = target.find('.glyphicon-plus');
        btn_add_element.click( function() { add_elements(mode, target); } );
    }

    function add_btn_edit_json( input, _setup_modal ) {
        var btn = $('<span class="jsoneditor jsoneditor-open glyphicon glyphicon-pencil" title="open json editor"></span>');
        btn.click(function(){
          if ( _setup_modal ) { setup_modal(); }
          process( input );
        });
        input.before(btn);
    }

    // adds a button to start the JSONEditor to each input element.
    JSONEditor.init = function(inputs) {
        inputs.each(function() {
          var input = $(this);
          add_btn_edit_json( input, true );
        });
    };

    return JSONEditor;
}( window.JSONEditor = window.JSONEditor || {} ));
