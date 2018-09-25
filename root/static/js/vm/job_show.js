(function( epplication, undefined ) {
    'use strict';

    if (!window.location.pathname.match(/^\/job\/\d+\/show/)) {return}

    function set_job(self, data){
        self.status(data.status);

        if (data.summary.duration) {
            self.duration(Number(data.summary.duration).toFixed(2) + ' seconds');
        }

        if (data.summary.num_steps) {
            self.num_steps(data.summary.num_steps + ' steps');
        }

        if (data.summary.errors) {
            self.errors(data.summary.errors + ' errors');
        }

        if (   data.status === 'error'
            || data.status === 'export_error'
            || data.summary.errors > 0
        ) {
            self.status_class('btn btn-xs btn-default btn-danger reset-pointer');
        }
        else if (data.status === 'in_progress' || data.status === 'pending' ) {
            self.status_class('btn btn-xs btn-default btn-info reset-pointer');
        }
        else if (data.status === 'export_pending'
            || data.status === 'exporting'
            || data.status === 'exported'
        ) {
            self.status_class('btn btn-xs btn-default btn-info reset-pointer');
        }
        else if (data.status === 'finished') {
            self.status_class('btn btn-xs btn-default btn-success reset-pointer');
        }
    }

    epplication.JobShowViewModel = function(job_reload_time) {
        var self = this;

        self.job_id       = $('#job').data('jobid');
        self.test_name    = $('#job').data('testname');
        self.status       = ko.observable();
        self.duration     = ko.observable();
        self.num_steps    = ko.observable();
        self.errors       = ko.observable();
        self.status_class = ko.observable();

        document.title    = self.test_name;

        var load_job_cb = function(data) {
            set_job(self, data);
            if (self.status() === 'in_progress' || self.status() === 'pending') {
                setTimeout(self.load, job_reload_time()*1000);
            }
        };
        self.load = function(){
                    $.ajax({
                        url: '/api/job/' + self.job_id,
                        method: 'GET',
                        traditional: true,
                        success: load_job_cb,
                    });
        };
        self.load();
    };
}( window.epplication = window.epplication || {} ));
