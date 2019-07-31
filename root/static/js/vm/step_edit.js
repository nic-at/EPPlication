(function( epplication, undefined ) {
    'use strict';

    if (
        !window.location.pathname.match(/\/branch\/\d+\/test\/\d+\/step\/\d+\/edit/)
        &&
        !window.location.pathname.match(/\/branch\/\d+\/test\/\d+\/step\/create/)
    ) {
        return;
    }

    epplication.StepEditViewModel = function() {
        var self = this;

        var subtest_list = $('#subtest_id');
        if (!subtest_list.length) {return}

        var load_test_cb = function(data) {
            var subtest_id = $('#hidden_subtest_id').val();
            var empty_select = '<option id="subtest_id.0" value="">Select ...</option>';
            subtest_list.find('option').remove();
            subtest_list.append(empty_select);
            $.each(data, function(index, value) {
                var option = $('<option>', {
                                            value: value.id,
                                            id: 'subtest_id.'+index+1
                                           }).text(value.name);
                if (value.id == subtest_id) {
                    option.attr('selected', true);
                }
                subtest_list.append(option);
            });
        };

        self.load = function() {
            var branch_id = $('#active-branch').data('active-branch-id');
            $.ajax({
                url: '/api/test',
                method: 'GET',
                traditional: true,
                data: { branch_id: branch_id, tags: epplication.active_tags() },
                success: load_test_cb,
            });
        };
        self.load();
        epplication.active_tags.subscribe(function(newValue) {
            self.load()
        });
    };

}( window.epplication = window.epplication || {} ));
