(function( epplication, undefined ) {
    'use strict';

    if (!window.location.pathname.match(/\/branch\/\d+\/test\/\d+\/show/)) {return}
    var sortable = $('#steps');
    if (!sortable.length) {return}


    function Tag(data){
        var self = this;
        self.id   = data.id;
        self.name = data.name;
        self.color = data.color;
    }

    function Step(data){
        var self = this;
        self.id         = data.id;
        self.test_id    = data.test_id;
        self.active     = data.active;
        self.highlight  = data.highlight;
        self.condition  = data.condition;
        self.name       = data.name;
        self.type       = data.type;
        self.parameters = data.parameters;

        self.details_html = '';
        self.details_text = '';

        var branch_id = $('#active-branch').data('active-branch-id');

        var json = JSON.parse(self.parameters)
        switch(self.type) {
            case 'DataCmp':
            case 'PrintVars':
            case 'ClearVars':
            case 'DBConnect':
            case 'DBDisconnect':
            case 'Diff':
            case 'EPPConnect':
            case 'EPPDisconnect':
                break;
            case 'SeleniumConnect':
                self.details_text = json.identifier + ' => ' + json.host + ':' + json.port;
                break;
            case 'SeleniumRequest':
                self.details_text = '(' + json.identifier + ') ' + json.url;
                break;
            case 'SeleniumJS':
                self.details_html = epplication.add_modal('javascript', json.javascript);
                self.details_text = '(' + json.identifier + ') ';
                break;
            case 'SeleniumInput':
            case 'SeleniumClick':
                self.details_text = '(' + json.identifier + ') ' + json.locator + ' = ' + json.selector;
                break;
            case 'SeleniumContent':
                self.details_text = '(' + json.identifier + ') ' + json.variable + ' => ' + json.content_type;
                break;
            case 'SeleniumDisconnect':
                self.details_text = json.identifier;
                break;
            case 'VarCheck':
            case 'VarVal':
                self.details_text = json.variable + ' => ' + json.value;
                break;
            case 'Multiline':
                self.details_html = epplication.add_modal(json.variable, json.value);
                self.details_text = json.variable;
                break;
            case 'Transformation':
                self.details_text = json.var_result + ' => ' + json.transformation + '(' + json.input + ')';
                break;
            case 'Script':
                self.details_text = json.var_stdout + ' => ' + json.command;
                break;
            case 'SSH':
                self.details_text = json.ssh_user + '@' + json.ssh_host + ':' + json.ssh_port
                          + ' ' + json.var_stdout + ' => ' + json.command;
                break;
            case 'Math':
                self.details_text = json.variable + ' => ' + json.value_a + ' ' + json.operator + ' ' + json.value_b;
                break;
            case 'DateAdd':
                self.details_text = json.variable + ' => ' + json.date + ' + ' + json.duration;
                break;
            case 'DateCheck':
                self.details_text = json.date_got + ' => ' + json.date_expected + ' +/- ' + json.duration;
                break;
            case 'DateFormat':
                self.details_text = json.variable + ' => ' + json.date + ' (' + json.date_format_str + ')';
                break;
            case 'VarRand':
                self.details_text = json.variable + ' => ' + json.rand;
                break;
            case 'VarCheckRegExp':
                self.details_text = json.value + ' => /' + json.regexp + '/' + json.modifiers;
                break;
            case 'VarQueryPath':
            case 'CountQueryPath':
                self.details_html = epplication.add_modal(self.name, json.input);
                self.details_text = json.var_result + ' => ' + json.query_path;
                break;
            case 'HTTP':
            case 'REST':
                self.details_html = epplication.add_modal(self.name, json.body);
                self.details_text = json.method + ' ' + json.path + ' (check_success => ' + json.check_success + ')';
                break;
            case 'Whois':
                self.details_text = json.domain;
                break;
            case 'SubTest':
                self.details_html = epplication.add_modal(self.name, '', '/branch/' + branch_id + '/test/' + json.subtest_id + '/details')
                          + ' <a href="/branch/' + branch_id + '/test/' + json.subtest_id + '/show">' + json.subtest_name + '</a>';
                break;
            case 'ForLoop':
                self.details_html = epplication.add_modal(self.name, '', '/branch/' + branch_id + '/test/' + json.subtest_id + '/details')
                          + ' <a href="/test/' + json.subtest_id + '/show">' + json.subtest_name + '</a>'
                self.details_text = '(' + json.variable + ')';
                break;
            case 'Comment':
                self.details_html = epplication.add_modal(self.name, json.comment);
                break;
            case 'SOAP':
                self.details_html = epplication.add_modal(self.name, json.method + "\n\n" + json.body);
                break;
            case 'EPP':
                self.details_html = epplication.add_modal(self.name, json.body);
                break;
            case 'DB':
                self.details_html = epplication.add_modal(self.name, json.sql);
                break;
            default:
                epplication.show_error('unknown step type: ' + self.type);
        }

        self.edit_url = function() {
            return '/branch/' + branch_id + '/test/' + self.test_id + '/step/' + self.id + '/edit';
        };
        self.move_to = function(index) {
                    $.ajax({
                        url: '/api/step?test_id=' + self.test_id + '&step_id=' + self.id,
                        method: 'POST',
                        data: { index: index }
                    });
        };
    }

    epplication.StepViewModel = function() {
        var self = this;
        self.tags       = ko.observableArray([]);
        self.show_tag_select = ko.observable(false);
        self.show_name_input = ko.observable(false);
        self.available_tags  = ko.observableArray([]);
        self.selected_tag    = ko.observable();
        self.steps      = ko.observableArray([]);
        self.step_stash = ko.observableArray([]).extend({ persist: 'step_stash' });
        self.show_stash = ko.observable(false).extend({ persist: 'show_stash' });
        self.test_id    = sortable.data('testid');
        self.test_name  = ko.observable(sortable.data('testname'));
        self.new_test_name = ko.observable(self.test_name());
        document.title  = self.test_name();
        self.loaded     = false;

        self.test_name.subscribe(function(new_test_name) {
            document.title = new_test_name;
        });
        self.custom_index = function(step, index) {
                    var ret = '';
                    if (step.active) {
                        ret = 0;
                        for ( var i = 0; i <= index; i++ ) {
                            if (self.steps()[i].active) { ret++; }
                        }
                    }
                    return ret;
        };

        // if no steps exist, insert dummy so the drop target isn't empty
        $('#step_stash').hover(function(){
            if (self.loaded && sortable.find('tr').length === 0) {
                sortable.append('<tr class="drop-dummy"><td colspan="7">Drop here!</td></tr>');
            }
        });

        self.moveStep = function(arg,ev) {
            var source = $(arg.sourceParentNode);
            var source_id = source.attr('id');
            var index = typeof arg.targetIndex != 'undefined'
                            ? arg.targetIndex
                            : 0;
            if (source_id === 'steps') {
                arg.item.move_to(index);
            }
            else if (source_id === 'step_stash_body') {
                var dropdummy = sortable.find('.drop-dummy');
                if(dropdummy.length > 0) {
                    dropdummy.remove();
                    index = 0;
                }
                self.createStep(arg.item, index);
                // press CTRL to restore a copy of the stash item.
                if (ev.ctrlKey) {
                    self.step_stash.splice(arg.sourceIndex, 0, arg.item);
                }
            }
            else { epplication.show_error('Unknown source id: ', source_id); }
        };
        self.deleteStep = function(step, withConfirm) {
            if (withConfirm) {
                if (!confirm("Are you sure you want to delete this step?")) {
                    return;
                }
            }
            $.ajax({
                url: '/api/step?test_id=' + step.test_id + '&step_id=' + step.id,
                method: 'DELETE',
                success: function() {
                            self.steps.remove(step);
                }
            });
        };
        self.mv_to_stash = function(step,ev) {
            self.show_stash(true);
            var step_data = jQuery.extend({},step);
            step_data.id = '';
            step_data.test_id = '';
            self.step_stash.push(step_data);
            if (!ev.ctrlKey) {
                self.deleteStep(step, false);
            }
        };
        self.removeFromStash = function(index) {
            self.step_stash.splice(index,1);
        };
        self.createStep = function(step, index) {
                    var step_data = jQuery.extend({}, step);
                    delete step_data.details_html;
                    delete step_data.details_text;
                    $.ajax({
                        url: '/api/step?test_id=' + self.test_id,
                        method: 'PUT',
                        contentType: 'application/json',
                        data: ko.toJSON({ step_data: step_data, index: index }),
                        success: function(data) {
                                    self.steps()[index] = new Step(data);
                                    self.steps.valueHasMutated();
                                 },
                    });
        };
        function highlight_step() {
            var step_id = window.location.hash;
            if (step_id === '') { return; }
            var window_top_offset = 70;
            var scroll_duration   = 500;
            var re                = /^#step-\d+$/;
            if (!step_id.match(re)) { return; }
            var el = $(step_id);
            if(!el.length) { return; }
            el.addClass('warning');
            $('html, body').animate(
                {
                    scrollTop: el.offset().top - window_top_offset
                },
                scroll_duration
            );
        }
        self.select_tag = function() {
            self.show_tag_select(true);
        };
        self.selected_tag.subscribe(function(new_tag_id) {
          if(typeof new_tag_id === 'number') {
            self.add_tag(new_tag_id);
            self.show_tag_select(false);
          }
        });
        self.enable_name_input = function() {
            self.show_name_input(true);
            $('#inputName').focus();
        };
        self.updateTestName = function(d,e) {
            if (e.keyCode === 13) { // enter
                    if(self.new_test_name().length <= 0) {
                        epplication.show_error('Please provide at least 1 character for a new test name.');
                        return false;
                    }
                    // same regex as in lib/EPPlication/Web/Form/Test.pm
                    if(!self.new_test_name().match(/^[\ \w\-\(\):]+$/)) {
                        epplication.show_error('Contains invalid characters.');
                        return false;
                    }
                    $.ajax({
                        url: '/api/test/' + self.test_id,
                        method: 'PUT',
                        contentType: 'application/json',
                        data: ko.toJSON({ test_name: self.new_test_name() }),
                        success: function(data) {
                            self.show_name_input(false);
                            self.test_name(self.new_test_name());
                        },
                    });
            }
            else if (e.keyCode === 27) { // escape
                self.show_name_input(false);
                return false;
            }
            return true;
        };
        self.add_tag = function(new_tag_id) {
                    $.ajax({
                        url: '/api/tag/tag_test',
                        method: 'POST',
                        contentType: 'application/json',
                        data: ko.toJSON({ test_id: self.test_id, tag_id: new_tag_id }),
                        success: function(data) { self.load_tags() },
                    });
        };
        self.remove_tag = function(tag_id) {
                    $.ajax({
                        url: '/api/tag/tag_test',
                        method: 'DELETE',
                        contentType: 'application/json',
                        data: ko.toJSON({ test_id: self.test_id, tag_id: tag_id }),
                        success: function(data) { self.load_tags() },
                    });
        };
        self.load_tags = function(){
                    $.ajax({
                        url: '/api/tag/tag_test?test_id=' + self.test_id,
                        method: 'GET',
                        contentType: 'application/json',
                        success: function(data) {
                                    var mappedTags = $.map(
                                        data.tags,
                                        function(item) {
                                            return new Tag(item);
                                        }
                                    );
                                    self.tags(mappedTags);
                                    var mappedAvailableTags = $.map(
                                        data.available_tags,
                                        function(item) {
                                            return new Tag(item);
                                        }
                                    );
                                    self.available_tags(mappedAvailableTags);
                                }
                    });
        };
        self.load = function(){
                    self.load_tags();
                    $.ajax({
                        url: '/api/step?test_id=' + self.test_id,
                        method: 'GET',
                        contentType: 'application/json',
                        success: function(data) {
                                    var mappedSteps = $.map(
                                        data.steps,
                                        function(item) {
                                            return new Step(item);
                                        }
                                    );
                                    self.steps(mappedSteps);
                                    highlight_step();
                                    self.loaded = true;
                                }
                    });
        };
        self.load();
    };
}( window.epplication = window.epplication || {} ));
