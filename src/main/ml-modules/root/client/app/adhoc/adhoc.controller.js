'use strict';

angular.module('demoApp').
factory('$click', function() {
	  return {
	    on: function(element) {
	      var e = document.createEvent("MouseEvent");
	      e.initMouseEvent("click", false, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
	      element.dispatchEvent(e);
	    }
	  };
	})
  .controller('AdhocCtrl', function($state,$scope, $http, $sce, Auth, User, AdhocState,$window,$timeout,$click,$stateParams) {
    var ctrl = this;

      $scope.initialSearchDone = false;
    // Determine if we arrived here from a back button click
    var displayLastResults = AdhocState.getDisplayLastResults();
    // Restore the saved state
    AdhocState.restore($scope);
    // Keep the page number in sync
    $scope.$watch('queryCurrentPage', function(page){
      AdhocState.setPage(page);
    });

      if ( $stateParams.deparams ) {
          $scope.loadDatabase = $stateParams.deparams.database;
          $scope.loadDocType= $stateParams.deparams.docType;
          $scope.loadQueryName = $stateParams.deparams.queryName;
          $scope.loadViewName = $stateParams.deparams.viewName;
      }

      $scope.openDetails = function(database,uri) {
          AdhocState.save($scope);
          $state.go('detail',
              {deparams: {
                      database:database,
                      uri: uri}})
      };

    ctrl.suggestValues = function(field) {
      return $http.get('/api/suggest-values', {
        params: {
          docType : encodeURIComponent($scope.selectedDocType),
          queryName: encodeURIComponent($scope.selectedQuery),
          rangeIndex: encodeURIComponent(field.item.rangeIndex),
          qtext: encodeURIComponent(field.value)
        }
      })
      .then(function(response) {
        if (response.data && response.data.values) {
          return response.data.values;
        }
        else {
          return [];
        }
      });
    };
    function highlightText(value, termsToHighlight) {
      var str = value;
      _.forEach(termsToHighlight, term => str = str.replace(term, '<span class="search-match-highlight">' + term + '</span>'));
      return str;
    }

    $scope.to_value = function(key, values, result) {
      var matchesObj = result['$matches'];
      var termsToHighlight = _(matchesObj).filter({ column: key }).map(f => _.map(f.parts, 'highlight')).flatten().value();
      var result = '';

      if (Array.isArray(values)) {
        var str = ""
        for (var i in values) {
          str = str + '<div class="multi-value-box">' + values[i] + '</div>';
        }
        result = highlightText(str, termsToHighlight);
      } else {
        result = highlightText(values, termsToHighlight);;
      }

      return $sce.trustAsHtml(result);
    };

    $http.get('/api/adhoc').success(function(data, status, headers, config) {
      if (status == 200 && Array.isArray(data)) {
        $scope.databases = data;
        if ( $scope.loadDatabase != undefined) {
            $scope.selectedDatabase = $scope.loadDatabase;
        }
      }
      if (status == 401) {
        $scope.message = "Login failure. Please log in.";
        Auth.logout();
      }
    });

    $scope.$watch('selectedDatabase', function(newValue) {
      if(!displayLastResults) {
        $scope.selectedDocType = '';
        $scope.selectedQuery = '';
        $scope.selectedView = '';
        if (typeof(newValue) !== 'undefined' && newValue != '') {
          $scope.doctypes = [];
          $scope.queries = [];
          $scope.views = [];
          $http.get('/api/listTypeDiscriminator', {
              params: {
                  database : encodeURIComponent(newValue)
              }
          }).success(function(data, status, headers, config) {
            if (status == 200) {
              $scope.doctypes = data;
              if ($scope.loadDocType  ) {
                  $scope.selectedDocType = $scope.loadDocType
              } else if ($scope.doctypes.length > 0) {
                $scope.selectedDocType = $scope.doctypes[0];
              }
            }
            if (status == 401) {
              $scope.message = "Login failure. Please log in.";
              Auth.logout();
            }
          });
        }
      }
    });

    $scope.$watch('selectedDocType', function(newValue) {
      if(!displayLastResults) {
        $scope.selectedQuery = '';
        $scope.selectedView = '';
        $scope.queries = [];
        $scope.views = [];
        if ( newValue ) {
          $http.get('/api/crud/listQueries', {
              params: {
                  database : encodeURIComponent($scope.selectedDatabase),
                  docType : encodeURIComponent(newValue)
              }
          }).success(function(
            data, status, headers, config) {
            if (status == 200) {
              $scope.queries = data;
              if ( $scope.loadQueryName  ) {
                  $scope.selectedQuery = $scope.loadQueryName
              } else {
                  if ($scope.queries && $scope.queries.queries.length > 0) {
                    $scope.selectedQuery = $scope.queries.queries[0].queryName;
                  }
                }
            }
            if (status == 401) {
              $scope.message = "Login failure. Please log in.";
              Auth.logout();
            }
          });
        }
      }
    });

    $scope.$watch('selectedQuery', function(newValue) {
        if (displayLastResults || !newValue ) {
        return;
      }
        $scope.textFields = []; // reset query fields
        $http.get('/api/crud/listViews', {
            params: {
                docType : encodeURIComponent($scope.selectedDocType),
                queryName : encodeURIComponent(newValue),
                filterDefaultView : false
            }
        }).success(function(
            data, status, headers, config) {
            if (status == 200) {
                $scope.views = data;
                if ( $scope.loadViewName  ) {
                    $scope.selectedView = $scope.loadViewName
                    if ( $scope.initialSearchDone == false ) {
                        $scope.initialSearchDone = true
                        $scope.search(false)
                    }
                } else {
                    if ($scope.views && $scope.views.views.length > 0) {
                        $scope.selectedView = $scope.views.views[0].viewName;
                    }
                }
            }
            if (status == 401) {
                $scope.message = "Login failure. Please log in.";
                Auth.logout();
            }
        });
        $http.get('/api/crud/getQueryView', {
            params: {
                docType : encodeURIComponent($scope.selectedDocType),
                queryName : encodeURIComponent($scope.selectedQuery)
            }
        }).success(function(
            data, status, headers, config) {
            if (status == 200) {
                $scope.textFields = _.map(data.formLabels, function(o) { // do some processing to the field definitions before passing
                    var opt = angular.copy(o);
                    var dataTypeHint = opt.dataType ? ' (' + opt.dataType.trim() + ')' : '';
                    opt.placeholderText = opt.label + dataTypeHint;
                    return opt;
                });
            }
            if (status == 401) {
                $scope.message = "Login failure. Please log in.";
                Auth.logout();
            }
        });
      var query = _.find($scope.rows, { name: newValue }); // find query object
      if (typeof(query) === 'undefined') {
        return;
      }

    });

    $scope.getField = function(field) {
      var input = $scope.inputField[field];
      if (typeof(input) !== 'undefined' && input !== null) {
        return input;
      } else {
        return '';
      }
    };

    $scope.clickSearch = function(form) {
      AdhocState.save($scope);
      if (form.$valid) {
        $scope.queryCurrentPage = 1;
        $scope.search(false);
      }
    };
    $scope.showExportCsv = function() {
    	var count =parseInt($scope.results['result-count']);
    	var maxExportRecords= parseInt($scope.results['max-export-records'])
    	var limitTotalFiles=50;
        if(count > maxExportRecords){
        	var links=[];
        	for( var i=1; i<count;i=i+maxExportRecords){
        		var end=i+maxExportRecords-1
        		links.push($scope.selectedView+"["+i+" to "+(end>count?count:end)+"].csv")
        		limitTotalFiles--;
        		if(limitTotalFiles<=0){
        			break;
        		}
        	}
        	$scope.links=links;
        	$("#exportCsvModal").modal();
        }
        else{
        	$scope.search(true,1);
        	$scope.links=[];
        }
      };
    $scope.exportCsv = function(pageNumber) {
    	$scope.search(true,pageNumber);
    };

    $scope.search = function(exportCsv,pageNumber) {
      if (!$scope.selectedDatabase || !$scope.selectedDocType || !$scope.selectedQuery || !
        $scope.selectedView) {
        var missing = '';
        if (!$scope.selectedDatabase) {
          missing = 'database'
        } else if (!$scope.selectedDocType) {
          missing = 'type discriminator'
        } else if (!$scope.selectedQuery) {
          missing = 'query'
        } else if (!$scope.selectedView) {
          missing = 'view'
        }
        $scope.message = 'Error!!!! Please make sure you have a ' + missing + ' selected!';
        return;
      }
      if(!pageNumber){
      	pageNumber= $scope.queryCurrentPage
      }
      if(!exportCsv){
    	$scope.message = 'Searching...';
    	$scope.results = {};
      }
      $scope.includeMatches = !!$scope.searchText || _.some($scope.inputField || []);
      $http.get('/api/search', {
        params: {
          database: $scope.selectedDatabase,
          searchText: $scope.searchText,
          docType: $scope.selectedDocType,
          queryName: $scope.selectedQuery,
          viewName: $scope.selectedView,
          id1: $scope.getField(1),
          id2: $scope.getField(2),
          id3: $scope.getField(3),
          id4: $scope.getField(4),
          id5: $scope.getField(5),
          id6: $scope.getField(6),
          id7: $scope.getField(7),
          id8: $scope.getField(8),
          id9: $scope.getField(9),
          id10: $scope.getField(10),
          id11: $scope.getField(11),
          id12: $scope.getField(12),
          id13: $scope.getField(13),
          id14: $scope.getField(14),
          id15: $scope.getField(15),
          excludeversions: 1,
          excludedeleted: 1,
          go: 1,
          pagenumber: pageNumber,
          exportCsv:exportCsv,
          includeMatches: $scope.includeMatches
        }
      }).success(function(data, status, headers, config) {
    	  if(exportCsv){
    		  
    		  var downloadFile = function downloadFile() {
    			  var title= $scope.selectedView+".csv";
    			  
    			  if(!pageNumber){
    				  pageNumber="";
    			  }
    			  else{
    				  if($scope.links[(pageNumber-1)]){
    					  title= $scope.links[(pageNumber-1)];
    				  }
    				  else{
    					  title = $scope.selectedView+pageNumber+".csv";
    				  }
    			  }
    			  
    			  var blob = new Blob([data?data.toString():""], {type: 'text/csv'});
    	           if (navigator.appVersion.toString().indexOf('.NET') > 0)
    	               window.navigator.msSaveBlob(blob, title);
    	            else
    	            {
    	              var url = (window.URL || window.webkitURL).createObjectURL(blob)
    	              var element=$("#hiddenDiv1") 
    	              element.append("<a download=\"" + title + "\" href=\"" + url + "\"></a>");
    	              var a_href = element.find('a')[0];
    	               
    	              $click.on(a_href);
    	              $timeout(function() {(window.URL || window.webkitURL).revokeObjectURL(url)});
    	               
    	              element[0].removeChild(a_href);
    	            }
    		    };
    		    downloadFile();
    	  }
    	  else{
          if ( data == undefined || data.results == undefined || data.results.length == 0) {
              $scope.message = 'No documents found';
              return
          }
    		  $scope.message = '';
          if(data['display-order'] === 'alphabetical'){
            var cols = data['results-header'].slice(1).sort(function (a, b) {
              return a.toLowerCase().localeCompare(b.toLowerCase());
            });
            cols.push(data['results-header'][0]);
            data['results-header'] = cols;
          }else {
            // file order
            var cols = data['results-header'].slice(1);
            cols.push(data['results-header'][0]);
            data['results-header'] = cols;
          }
    	    $scope.results = data;
    	    $scope.queryCurrentPage = $scope.results['current-page'];
    	  }
        
      }).error(function(data, status) {
        if (status == 500) {
          $scope.message = "Server Error, please make sure you didn't change the inputs";
        }
        if (status == 401) {
          $scope.message = "Login failure. Please log in."
          Auth.logout();
        }
      });
    };

    // Execute search with saved form state
    if(displayLastResults) {
      $scope.search(false);
    }

  });
