(function( epplication, undefined ) {
    'use strict';

    if (!window.location.pathname.match(/^\/branch\/\d+\/test\/list/)) {return}

    function Test(data){
        var self = this;
        self.id  = data.id;
        self.branch_id = data.branch_id;
        self.name = data.name;
        self.tags = ko.observableArray(data.tags);
        self.clone = function() {
                    $.ajax({
                        url: '/api/test/clone',
                        method: 'POST',
                        data: { test_id: self.id },
                        success: function(data, status, jqxhr) {
                            location.href = jqxhr.getResponseHeader('location');
                        }
                    });
        };
        self.create_job = function(job_type) {
                    var data = { test_id: self.id, job_type: job_type };
                    var config_id = $('#active-config').data('active-config-id');
                    if (config_id) { data.config_id = config_id; }
                    $.ajax({
                        url: '/api/job',
                        method: 'POST',
                        data: ko.toJSON(data),
                        contentType: 'application/json; charset=UTF-8',
                        success: function(data, status, jqxhr) {
                            location.href = jqxhr.getResponseHeader('location');
                        }
                    });
        };
    }

    epplication.TestViewModel = function() {
        var self = this;

        document.title = 'Tests';

        self.search_query = ko.observable('comment: name: ').extend({ persist: 'test_search_query' });
        self.tests = ko.observableArray([]);
        self.deleteTest = function(test) {
            if (!confirm("Are you sure you want to delete this test?")) {
                return;
            }
            $.ajax({
                url: '/api/test/' + test.id,
                method: 'DELETE',
                success: function() {
                            self.tests.remove(test);
                }
            });
        };
        var load_test_cb = function(data) {
            var mappedTests = $.map(
                data,
                function(item) {
                    return new Test(item);
                }
            );
            self.tests(mappedTests);
        };
        self.load = function(){
                    var branch_id = $('#active-branch').data('active-branch-id');
                    $.ajax({
                        url: '/api/test',
                        method: 'GET',
                        traditional: true,
                        data: { branch_id: branch_id, search: self.search_query(), tags: epplication.active_tags() },
                        success: load_test_cb,
                    });
        };
        self.load();
        epplication.active_tags.subscribe(function(newValue) {
            self.load()
        });
    };
}( window.epplication = window.epplication || {} ));
