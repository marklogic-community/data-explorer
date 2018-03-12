'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('detail', {
        url: '/detail',
        params: {
              deparams: null
        },
        templateUrl: 'app/detail/detail.html',
        controller: 'DetailCtrl',
        authenticate: true
      });
  });