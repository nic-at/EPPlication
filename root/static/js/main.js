(function( epplication, undefined ) {
    'use strict';

    if ( window.location.pathname.match(/\/tag\/list/)) { document.title = 'Tags' }
    else if ( window.location.pathname.match(/\/user\/list/)) { document.title = 'Users' }
    else if ( window.location.pathname.match(/\/report\/list/)) { document.title = 'Reports' }
    else if ( window.location.pathname.match(/\/help/)) { document.title = 'Help' }

    epplication.show_error = function(error_msg) {
      $('#content').prepend(
          '<div role="alert" class="alert alert-danger">'
        + '  <button data-dismiss="alert" class="close" type="button"><span aria-hidden="true">&times;</span></button>'
        + '  <p>'+error_msg+'</p>'
        + '</div>'
      );
    };

    $( document ).ajaxStart(function() {
      $('.navbar-brand').addClass('ajax-in-progress');
    });
    $( document ).ajaxStop(function() {
      $('.navbar-brand').removeClass('ajax-in-progress');
    });
    $(document).ajaxError(function(event, jqxhr, settings, thrownError) {
      var error_msg = ((jqxhr.responseJSON || {}).error) || thrownError || 'AJAX Error'; // avoid type errors
      epplication.show_error(error_msg);
    });

    //
    // add modal
    //
    epplication.add_modal = function (header,body,remote) {
        var entityMap = {
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': '&quot;',
          "'": '&#39;',
          "/": '&#x2F;'
        };

        function escapeHtml(string) {
          return String(string).replace(/[&<>"'\/]/g, function (s) {
            return entityMap[s];
          });
        }

        var random_id = Math.floor(Math.random() * (10000 - 1000)) + 1000;
        var body_el = typeof(remote) === 'undefined'
                      ? '     <pre>' + escapeHtml(body) + '</pre>     '
                      : '     <span class="glyphicon glyphicon-refresh"></span> Loading ...'
        var remote_attr = typeof(remote) === 'string' ? 'data-remote="' + remote + '"' : '';
        var btn =   '<button '
                  + 'data-target="#modal_'+random_id+'" data-toggle="modal" '
                  + remote_attr
                  + 'title="Show details" class="btn btn-default btn-xs">'
                  + '  <i class="glyphicon glyphicon-comment"></i>'
                  + '</button>';
        var modal =   '<div aria-labelledby="modal_label_'+random_id+'" aria-hidden="true" '
                    + 'role="dialog" class="modal" id="modal_'+random_id+'" style="display: none;">'
                    + '  <div class="modal-dialog modal-lg">'
                    + '    <div class="modal-content">'
                    + '      <div class="modal-header">'
                    + '        <button data-dismiss="modal" class="close">×</button>'
                    + '        <h3 id="modal_label_'+random_id+'">' + header + '</h3>'
                    + '      </div>'
                    + '      <div class="modal-body">      '
                    + body_el
                    + '      </div>'
                    + '    </div>'
                    + '  </div>'
                    + '</div>';
        return btn + modal;
    };

    //
    // JS to add warn message on input fields with leading/trailing whitespace
    //

    // if a fields value has leading/trailing whitespace add warning
    // class to field
    var check_trailing_whitespace = function(field) {
        var form_group = field.parents('.form-group');
        var parent     = field.parent();
        var val        = field.val();

        // select whitespace_warning_element
        var warn_msg           = 'Trailing/leading whitespace found!';
        var whitespace_warning = parent.find(".help-block:contains('" + warn_msg + "')");

        if ( /^\s|\s$/.test(val) ) {
            // add warning class, border and font yellow
            form_group.addClass('has-warning');

            // add whitespace warning
            if ( whitespace_warning.size() <= 0 ) {
                parent.append( $('<span class="help-block">' + warn_msg + '</span>') );
            }
        }
        else {
            // remove warning class, border and font yellow
            form_group.removeClass('has-warning');

            // remove whiteaspace warning
            whitespace_warning.remove();
        }
    };

    // custom jquery plugin
    (function($) {
        $.fn.warn_trailing_whitespace = function() {
            return this.each(function() {
                var field = $(this);
                check_trailing_whitespace(field);
                field.on('keyup', function() { check_trailing_whitespace(field) });
            });
        };
    }(jQuery));


    //
    // initialize epplication javascript
    //
    epplication.init = function() {
        JSONEditor.init($(':input.json-edit'));
        $('.detect-whitespace').warn_trailing_whitespace();
        $('.treejo').each(function() {
            var el = $(this);
            treejo.create(
                    el,
                    {
                        'window_top_offset':  70,      // navbar(50px) + padding(20px)
                        'html_node_closed':   '<i class="glyphicon glyphicon-plus" title="open node"></i>',
                        'html_node_opened':   '<i class="glyphicon glyphicon-minus" title="close node"></i>',
                        'html_node_reload':   '<i class="glyphicon glyphicon-refresh" title="reload child nodes"></i>',
                        'html_node_showall':  '<i class="glyphicon glyphicon-align-left" title="load all child nodes"></i>'
                    }
            );
        });

        function RootViewModel() {
            var self = this;
            self.stash_width = ko.observable(200).extend({ persist: 'stash_width' });
            self.job_reload_time = ko.observable(3).extend({ persist: 'job_reload_time' });
            if (typeof epplication.TagViewModel === 'function') {
                self.tag_vm = new epplication.TagViewModel();
            }
            if (typeof epplication.TestViewModel === 'function') {
                self.test_vm = new epplication.TestViewModel();
            }
            if (typeof epplication.StepViewModel === 'function') {
                self.step_vm = new epplication.StepViewModel();
            }
            if (typeof epplication.StepEditViewModel === 'function') {
                self.step_edit_vm = new epplication.StepEditViewModel();
            }
            if (typeof epplication.UserViewModel === 'function') {
                self.user_vm = new epplication.UserViewModel();
            }
            if (typeof epplication.JobViewModel === 'function') {
                self.job_vm = new epplication.JobViewModel();
            }
            if (typeof epplication.JobShowViewModel === 'function') {
                self.job_show_vm = new epplication.JobShowViewModel(self.job_reload_time);
            }
        }
        ko.applyBindings(new RootViewModel());
    };
}( window.epplication = window.epplication || {} ));

$(document).ready(function() {
    epplication.init();
});
