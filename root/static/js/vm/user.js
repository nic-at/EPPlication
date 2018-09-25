(function( epplication, undefined ) {
    'use strict';

    if (
        !window.location.pathname.match(/^\/job\/list/)
    ) {
        return;
    }

    function User(data, active_user) {
        var self  = this;
        self.id   = data.id;
        self.name = data.name;

        self.active = ko.computed( function() {
          return self.id === epplication.active_user();
        });
        self.toggle = function() {
          self.active()
            ? epplication.active_user(null)
            : epplication.active_user(self.id);
        };
    }

    epplication.UserViewModel = function() {
        var self = this;

        epplication.active_user = ko.observable().extend({ persist: 'active_user' });
        self.users = ko.observableArray([]);
        self.load = function(){
                    $.ajax({
                        url: '/api/user',
                        method: 'GET',
                        traditional: true,
                        success: function(data) {
                                    var mappedUsers = $.map(
                                        data,
                                        function(item) {
                                            return new User(item, epplication.active_user);
                                        }
                                    );
                                    mappedUsers.unshift(
                                        new User({name: 'all', id: 'all'}, epplication.active_user)
                                    );
                                    self.users(mappedUsers);
                                }
                    });
        };
        self.load();
    };
}( window.epplication = window.epplication || {} ));
