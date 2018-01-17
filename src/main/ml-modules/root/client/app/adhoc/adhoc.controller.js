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
  .controller('AdhocCtrl', function($scope, $http, $sce, Auth, User, AdhocState,$window,$timeout,$click) {
    // Determine if we arrived here from a back button click
    var displayLastResults = AdhocState.getDisplayLastResults();
    // Restore the saved state
    AdhocState.restore($scope);
    // Keep the page number in sync
    $scope.$watch('currentPage', function(page){
      AdhocState.setPage(page);
    });  

    $scope.to_trusted = function(html_code) {
      return $sce.trustAsHtml(html_code);
    };
    $scope.to_value = function(values) {
    	if(Array.isArray(values)){
    		var str=""
    		for (var i in values){
    			str=str + '<div class="multi-value-box">'+values[i]+'</div>'
    		}    			
    		return  $sce.trustAsHtml(str)
    	}
        return values;
      };
    $http.get('/api/adhoc').success(function(data, status, headers, config) {
      if (status == 200 && Array.isArray(data)) {
        $scope.databases = data;
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
          $http.get('/api/adhoc/' + newValue).success(function(data, status, headers, config) {
            if (status == 200) {
              $scope.doctypes = data;
              if ($scope.doctypes.length > 0) {
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
        if (typeof(newValue) !== 'undefined' && newValue != '') {
          $http.get('/api/adhoc/' + $scope.selectedDatabase + "/" + encodeURIComponent(newValue)).success(function(
            data, status, headers, config) {
            if (status == 200) {
              $scope.queries = data.queries;
              $scope.views = data.views;
              if ($scope.queries && $scope.queries.length > 0) {
                $scope.selectedQuery = $scope.queries[0].query;
              }
              if ($scope.views && $scope.views.length > 0) {
                $scope.selectedView = $scope.views[0];
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
      if(!displayLastResults) {
        $scope.textFields = [];
        if (typeof(newValue) !== 'undefined' && newValue != '') {
          for (var i = 0; i < $scope.queries.length; i++) {
            if ($scope.queries[i].query == newValue) {
              var dataTypes = $scope.queries[i]['form-datatypes']
              var formLabels = $scope.queries[i]['form-labels']
              var arr = new Array(formLabels.length)
              for ( i = 0 ; i < formLabels.length ; i++ ) {
                 var formLabel = formLabels[i]
                 var dataTypeString = "";
                 var dt = "text"
                 if ( i < dataTypes.length ) {
                    var dataType = dataTypes[i]
                    dt = dataType
                    if ( dataType != null && dataType.trim().length > 0 ) {
                                  dataTypeString = " ("+dataType.trim()+")"
                     }
                 }
                 arr[i] = new Array(3);
                 arr[i][0] = formLabel;
                 arr[i][1] = formLabel+dataTypeString
                 arr[i][2] = dt
              }
              $scope.textFields = arr
              $scope.dataTypes = dataTypes
              break;
            }
          }
        }
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
        $scope.currentPage = 1;
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
          missing = 'DocType'
        } else if (!$scope.selectedQuery) {
          missing = 'query'
        } else if (!$scope.selectedView) {
          missing = 'view'
        }
        $scope.message = 'Error!!!! Please make sure you have a ' + missing + ' selected!';
        return;
      }
      if(!pageNumber){
      	pageNumber= $scope.currentPage
      }
      if(!exportCsv){
    	$scope.message = 'Searching....';
    	$scope.results = {};
      }
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
          exportCsv:exportCsv
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
    		  $scope.message = '';
    	      $scope.results = data;
    	      $scope.currentPage = $scope.results['current-page'];
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