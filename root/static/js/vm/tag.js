(function( epplication, undefined ) {
    'use strict';

    if (
        !window.location.pathname.match(/^\/branch\/\d+\/test\/list/)
        &&
        !window.location.pathname.match(/^\/branch\/\d+\/test\/\d+\/step\/\d+\/edit/)
        &&
        !window.location.pathname.match(/^\/branch\/\d+\/test\/\d+\/step\/create/)
    ) {
        return;
    }

    function Tag(data) {
        var self   = this;
        self.id    = data.id;
        self.name  = data.name;
        self.color = data.color;

        self.active = ko.computed( function() {
            return -1 !== epplication.active_tags.indexOf(self.id);
        });
        self.toggle = function() {
            if( self.active() ) {
                var index = epplication.active_tags.indexOf(self.id);
                epplication.active_tags.splice(index,1);
            }
            else {
                epplication.active_tags.push(self.id);
            }
        };
    }

    epplication.TagViewModel = function() {
        var self = this;

        epplication.active_tags = ko.observableArray([]).extend({ persist: 'active_tags' });
        self.tags = ko.observableArray([]);

        // tags deleted in backend might still be present in active_tags stored in localStorage
        self.clean_active_tags = function(tags) {
            var tag_ids = $.map(
                tags,
                function(tag) { return tag['id']; }
            );
            // active_tags might be re-indexed due to splice()
            // iterate in reverse so we don't skip indices
            var i = epplication.active_tags().length;
            while (i--) {
                var tag = epplication.active_tags()[i];
                if (tag === 'all' || tag === 'untagged') {
                    continue; // skip "virtual" tags
                }
                var index = tag_ids.indexOf(tag);
                if (index === -1) {
                    epplication.active_tags.splice(index,1);
                }
            };
        };
        self.load = function(){
                    $.ajax({
                        url: '/api/tag',
                        method: 'GET',
                        traditional: true,
                        success: function(data) {
                                    self.clean_active_tags(data);
                                    var mappedTags = $.map(
                                        data,
                                        function(item) {
                                            return new Tag(item);
                                        }
                                    );
                                    mappedTags.unshift(
                                        new Tag({name: 'untagged', id: 'untagged', color: '#cce5ff'}),
                                        new Tag({name: 'all', id: 'all', color: '#cce5ff'})
                                    );
                                    self.tags(mappedTags);
                                }
                    });
        };
        self.load();
    };
}( window.epplication = window.epplication || {} ));
