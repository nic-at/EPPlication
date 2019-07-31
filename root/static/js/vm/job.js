(function( epplication, undefined ) {
    'use strict';

    if (!window.location.pathname.match(/\/job\/list/)) {return}

    function Job(data){
        var self = this;
        self.id       = data.id;
        self.created  = data.created;
        self.duration = data.duration;
        self.num_steps = data.num_steps;
        self.errors   = data.errors;
        self.user     = data.user;
        self.branch   = data.branch;
        self.config   = data.config;
        self.config_url = data.config_url;
        self.test_url = data.test_url;
        self.test     = data.test;
        self.comment  = data.comment ? epplication.add_modal('Comment', data.comment) : '';
        self.sticky   = data.sticky;
        self.status   = data.status;
        if (data.status === 'error' || data.errors > 0) {
            self.status_class = 'btn btn-xs btn-default btn-danger reset-pointer';
        }
        else if (data.status === 'in_progress' || data.status === 'pending' ) {
            self.status_class = 'btn btn-xs btn-default btn-info reset-pointer';
        }
        else if (data.status === 'export_pending'
            || data.status === 'exporting'
            || data.status === 'exported'
        ) {
            self.status_class = 'btn btn-xs btn-default btn-info reset-pointer';
        }
        else if (data.status === 'export_error') {
            self.status_class = 'btn btn-xs btn-default btn-danger reset-pointer';
        }
        else if (data.status === 'finished') {
            self.status_class = 'btn btn-xs btn-default btn-success reset-pointer';
        }
        self.show_url = data.show_url;
        self.edit_url = data.edit_url;
    }

    epplication.JobViewModel = function() {
        var self = this;

        document.title = 'Jobs';

        self.jobs = ko.observableArray([]);
        self.deleteJob = function(job) {
            if (!confirm("Are you sure you want to delete this job?")) {
                return;
            }
            $.ajax({
                url: '/api/job/' + job.id,
                method: 'DELETE',
                success: function() {
                            self.jobs.remove(job);
                }
            });
        };

        self.order_asc = true;
        self.order = function(vm, ev) {
	    self.order_asc(!self.order_asc());
	    var attr = ev.target.textContent.toLowerCase();
	    attr = attr === 'steps' ? 'num_steps' : attr; // label doesnt match vm attr
	    var cmp = function(a,b){
		if (!self.order_asc()) { // reverse sort order if clicked twice
		    var tmp = a;
		    a = b;
		    b = tmp;
		}
                switch(attr) {
                    case 'created':
			[a,b].forEach(function(val){
			    var pattern = /(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})/;
			    var date    = val[attr];
			    val[attr]   = date.replace(pattern, '$3-$2-$1-$4-$5-$6');
			});
                        break;
                    case 'duration':
			[a,b].forEach(function(val){
			    val[attr] = parseFloat(val[attr]);
			});
                        break;
                    case 'num_steps':
                    case 'errors':
			[a,b].forEach(function(val){
			    val[attr] = parseInt(val[attr]);
			});
                        break;
                }
		return a[attr] === b[attr]
		       ? 0
		       : ( a[attr] < b[attr] ? -1 : 1 );
	    };
	    self.jobs.sort(cmp);
        };

        var load_job_cb = function(data) {
            var mappedJobs = $.map(
                data,
                function(item) {
                    return new Job(item);
                }
            );
            self.jobs(mappedJobs);
        };
        self.load = function(){
            if (epplication.active_user()) {
              $.ajax({
                url: '/api/job',
                method: 'GET',
                traditional: true,
                data: { filter: epplication.active_user() },
                success: load_job_cb,
              });
            }
            else {
              self.jobs.removeAll();
            }
        };
        self.load();
        epplication.active_user.subscribe(function(newValue) {
            self.load()
        });
    };
}( window.epplication = window.epplication || {} ));
