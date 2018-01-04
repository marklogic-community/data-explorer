'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('detail', {
        url: '/detail/:database/*uri',
        templateUrl: 'app/detail/detail.html',
        controller: 'DetailCtrl',
        authenticate: true
      });
  });