'use strict';

angular.module('demoApp')
  .factory('$click', function() {
   return {
     on: function(element) {
       var e = document.createEvent("MouseEvent");
       e.initMouseEvent("click", false, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
       element.dispatchEvent(e);
     }
   };
  })
  .controller('AdhocCtrl', function($state,$scope, dataService, $http, $sce, Auth, User, AdhocState,$window,$timeout,$click,$stateParams) {
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
    $scope.collections ="---";
    $scope.fileFormat = "JSON";
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
        var databases = [];
        for (var key in data) {
          databases.push(JSON.parse(data[key]));
        }
        $scope.databases = databases;
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
            $scope.collections = data.collections
            $scope.fields = data.fields;
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
        window.scrollTo(0,0);
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
      if (!$scope.selectedDatabase || !$scope.selectedDocType || !$scope.selectedQuery || !$scope.selectedView) {
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

          // remove 'Database Name' header because we don't want to display that column in the results
          var colIdx = data['results-header'].indexOf('Database Name');
          if(colIdx !== -1){
            data['results-header'].splice(colIdx, 1);
          }
          if(data['display-order'] === 'alphabetical'){
            var cols = data['results-header'].slice(1).sort(function (a, b) {
              return a.toLowerCase().localeCompare(b.toLowerCase());
            });
            cols.push(data['results-header'][0]);
            data['results-header'] = cols;
          } else {
            // file order
            var cols = data['results-header'].slice(1);
            cols.push(data['results-header'][0]);
            data['results-header'] = cols;
          }
          console.log(data['results-header'])
          $scope.results = data;
          $scope.queryCurrentPage = $scope.results['current-page'];

          // Convert to CSV for graphinh
          $scope.clipboardText = $scope.results["results-header"].map(function(x){
            if (x && x != '""') {return '"'+x+'"'} else return "" }).join(",") + "\n"
            + $scope.results["results"].map(function(x) {
              return $scope.results["results-header"].map(function(h) {
                if (x[h] && x[h] != '""') { return '"' + x[h] + '"' } else { return "" }
              }).join(",")
            }).join("\n");
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

    ///////////////
    //  RAW GRAPHS CONTROLLER
    ///////////////


    $scope.loading = false;
    console.log("RawCtrl controller started.");

    // Clipboard
    $scope.$watch('clipboardText', text =>  {
      console.log("WATCH clipboardText");
      if (!text) return;
      console.log("WATCH clipboardText ENTERED");

      $scope.loading = true;

      if (is.url(text)) {
        $scope.importMode = 'url';
        $timeout(function() { $scope.url = text; });
        return;
      }

      try {
        var json = JSON.parse(text);
        selectArray(json);
        $scope.loading = false;
      }
      catch(error) {
        parseText(text);
      }

    });

    $scope.antani = d => {
      $scope.loading = true;
      var json = dataService.flatJSON(d);
      parseText(d3.tsvFormat(json))
    }

    // select Array in JSON
    function selectArray(json){
      $scope.json = json;
      $scope.structure = [];
      expand(json);
    }

    // parse Text
    function parseText(text){
      //  $scope.loading = false;
      $scope.json = null;
      $scope.text = text;
      $scope.parse(text);
    }

    // load File
    $scope.uploadFile = file =>  {

      if (file.size) {

        $scope.loading = true;

        // excel
        if (file.name.search(/\.xls|\.xlsx/) != -1 || file.type.search('sheet') != -1) {
          dataService.loadExcel(file)
          .then(worksheets => {
            $scope.fileName = file.name;
            $scope.loading = false;
            // multiple sheets
            if (worksheets.length > 1) {
              $scope.worksheets = worksheets;
            // single > parse
          } else {
            $scope.parse(worksheets[0].text);
          }
        })
        }

        // json
        if (file.type.search('json') != -1) {
          dataService.loadJson(file)
          .then(json => {
            $scope.fileName = file.name;
            selectArray(json);
          })
        }

        // txt
        if (file.type.search('text') != -1) {
          dataService.loadText(file)
          .then(text => {
            $scope.fileName = file.name;
            parseText(text);
          })
        }
      }
    };


    function parseData(json){

      $scope.loading = false;
      //  $scope.parsed = true;

      if (!json) return;
      try {
        selectArray(json);
      }
      catch(error) {
        console.log(error)
        parseText(json);
      }

    }

    // load URl
    $scope.$watch('url', url => {

      if(!url || !url.length) {
        return;
      }

      if (is.not.url(url)) {
        $scope.error = "Please insert a valid URL";
        return;
      }

      $scope.loading = true;
      var error = null;
      // first trying jsonp
      $http.jsonp($sce.trustAsResourceUrl(url), {jsonpCallbackParam: 'callback'})
      .then(response => {
        $scope.fileName = url;
        parseData(response.data);
      }, response => {

        $http.get($sce.trustAsResourceUrl(url), {responseType:'arraybuffer'})
        .then(response => {

          var data = new Uint8Array(response.data);
          var arr = new Array();
          for(var i = 0; i != data.length; ++i) arr[i] = String.fromCharCode(data[i]);
            var bstr = arr.join("");

          try {
            var workbook = XLS.read(bstr, {type:"binary"});
            var worksheets = [];
            var sheet_name_list = workbook.SheetNames;

            sheet_name_list.forEach(function(y) {
             var worksheet = workbook.Sheets[y];
             worksheets.push({
               name: y,
               text : XLSX.utils.sheet_to_csv(worksheet),
               rows: worksheet['!range'].e.r
             })
            });

            $scope.fileName = url;
            $scope.loading = false;

            // multiple sheets
            if (worksheets.length > 1) {
              $scope.worksheets = worksheets;
              // single > parse
            } else {
              parseText(worksheets[0].text);
            }
          }
          catch(error) {
            $scope.fileName = url;
            try {
              var json = JSON.parse(bstr);
              selectArray(json);
            }
            catch(error) {
              parseText(bstr);
            }
          }
        },
        response => {
          $scope.loading = false;
          $scope.error = "Something wrong with the URL you provided. Please be sure it is the correct address.";
        })

      });

    });


    $scope.samples = [
      { title : 'Biggest cities per continent', type : 'Distributions', url : 'data/cities.csv'},
      { title : 'Countries GDP', type : 'Other', url : 'data/countriesGDP.csv'},
      { title : 'Cars', type : 'Multivariate', url : 'data/multivariate.csv' },
      { title : 'Movies', type : 'Dispersions', url : 'data/dispersions.csv' },
      { title : 'Music industry', type: 'Time Series', url : 'data/music.csv' },
      { title : 'Lineup', type : 'Time chunks', url : 'data/lineup.tsv' },
      { title : 'Orchestras', type : 'Hierarchies (weighted)', url : 'data/orchestra.csv' },
      { title : 'Animal kingdom', type: 'Hierarchies', url : 'data/animals.tsv' },
      { title : 'Titanic\'s passengers', type : 'Multi categorical', url : 'data/titanic.tsv' },
      { title : 'Most frequent letters', type: 'Matrix (narrow)', url:'data/letters.tsv'}
    ]

    $scope.selectSample = sample => {

      if (!sample) return;
      $scope.text = "";
      $scope.loading = true;
      dataService.loadSample(sample.url).then(
        data => {
          $scope.text = data.replace(/\r/g, '');
          $scope.loading = false;
        },
        error => {
          $scope.error = error;
          $scope.loading = false;
        }
      );
    }//);

    $(document.getElementById("load-data")).on('dragenter', function(e){
      $scope.importMode = 'file';
      $scope.parsed = false;
      $scope.$digest();
    });

    $scope.$watch('dataView', function (n,o){
      if (!$('.parsed .CodeMirror')[0]) return;
      var cm = $('.parsed .CodeMirror')[0].CodeMirror;
      $timeout(function() { cm.refresh() });
    });

    // init
    $scope.raw = raw;
    $scope.data = [];
    $scope.metadata = [];
    $scope.error = false;
    //  $scope.loading = true;

    $scope.importMode = 'clipboard';

    $scope.categories = ['Hierarchies', 'Time Series', 'Distributions', 'Correlations', 'Others'];

    $scope.bgColors = {
      'Hierarchies': '#0f0',
      'Time Series': 'rgb(255, 185, 5)',
      'Distributions': 'rgb(5, 205, 255)',
      'Correlations': '#df0',
      'Others': '#0f0'
    }


    $scope.$watch('files', function () {
      $scope.uploadFile($scope.files);
    });

    $scope.log = '';

    $scope.files=[];


    $scope.$watch('importMode', function(){
      // reset
      $scope.parsed = false;
      $scope.loading = false;
      $scope.clipboardText = "";
      $scope.unstacked = false;
      $scope.text = "";
      $scope.data = [];
      $scope.json = null;
      $scope.worksheets = [];
      $scope.fileName = null;
      $scope.url = "";
      //$scope.$apply();
    })



    var arrays = [];

    $scope.unstack = function(){
      if (!$scope.stackDimension) return;
      var data = $scope.data;
      var base = $scope.stackDimension.key;

      var unstacked = [];

      data.forEach(row => {
        for (var column in row) {
          if (column == base) continue;
          var obj = {};
          obj[base] = row[base];
          obj.column = column;
          obj.value = row[column];
          unstacked.push(obj);
        }
      })
      $scope.oldData = data;
      parseText(d3.tsvFormat(unstacked));

      $scope.unstacked = true;

    }

    $scope.stack = function(){
      parseText(d3.tsvFormat($scope.oldData));
      $scope.unstacked = false;
    }


    function jsonTree(json){
      // mettere try
      var tree = JSON.parse(json);
      $scope.json = tree;
      $scope.structure = [];
      //console.log(JSON.parse(json));
      expand(tree);
    }


    function expand(parent){
      for (var child in parent) {
        if (is.object(parent[child]) || is.array(parent[child])) {
          expand(parent[child]);
          if (is.array(parent[child])) arrays.push(child);
        }
      }
      //console.log(child,parent[child])
    }


    // very improbable function to determine if pivot table or not.
    // pivotable index
    // calculate if values repeat themselves
    // calculate if values usually appear in more columns

    function pivotable(array) {

      var n = array.length;
      var rows = {};

      array.forEach(o => {
        for (var p in o) {
          if (!rows.hasOwnProperty(p)) rows[p] = {};
          if (!rows[p].hasOwnProperty(o[p])) rows[p][o[p]] = -1;
          rows[p][o[p]]+=1;
        }
      })

      for (var r in rows) {
        for (var p in rows[r]) {
          for (var ra in rows) {
            if (r == ra) break;
            //    if (p == "") break;
            if (rows[ra].hasOwnProperty(p)) rows[r][p]-=2.5;

          }
        }
      }

      var m = d3.values(rows).map(d3.values).map(d => { return d3.sum(d)/n; });
        //console.log(d3.mean(m),m)
        $scope.pivot = d3.mean(m);
    }




    $scope.parse = text => {

      if ($scope.model) $scope.model.clear();

      $scope.text = text;
      $scope.data = [];
      $scope.metadata = [];
      $scope.error = false;
      //$scope.importMode = null;
      //$scope.$apply();

      if (!text) return;

      try {
        var parser = raw.parser();
        $scope.data = parser(text);
        $scope.metadata = parser.metadata(text);
        $scope.error = false;
        pivotable($scope.data);
        $scope.parsed = true;

        $timeout(function() {
          $scope.charts = raw.charts.values().sort(function (a,b){ return d3.ascending(a.category(),b.category()) || d3.ascending(a.title(),b.title()) })
          $scope.chart = $scope.charts.filter(d => {return d.title() == 'Scatter Plot'})[0];
          $scope.model = $scope.chart ? $scope.chart.model() : null;
        });
      } catch(e){
        $scope.data = [];
        $scope.metadata = [];
        $scope.error = e.name == "ParseError" ? +e.message : false;
      }
      if (!$scope.data.length && $scope.model) $scope.model.clear();
      $scope.loading = false;
      var cm = $('.parsed .CodeMirror');
      if (cm && cm[0]) {
        cm = cm[0].CodeMirror;
        $timeout(function() { cm.refresh(); cm.refresh(); } );
      }
    }

    $scope.delayParse = dataService.debounce($scope.parse, 500, false);

    $scope.$watch("text", text => {
      if (!text) return;
      $scope.loading = true;
      $scope.delayParse(text);
    });

    $scope.$watch('error', error => {
      if (!$('.parsed .CodeMirror')[0]) return;
      var cm = $('.parsed .CodeMirror')[0].CodeMirror;
      if (!error) {
        cm.removeLineClass($scope.lastError,'wrap','line-error');
        return;
      }
      cm.addLineClass(error, 'wrap', 'line-error');
      cm.scrollIntoView(error);
      $scope.lastError = error;
    })

    $('body').mousedown(function (e,ui){
      if ($(e.target).hasClass("dimension-info-toggle")) return;
      $('.dimensions-wrapper').each(e => {
        angular.element(this).scope().open = false;
        angular.element(this).scope().$apply();
      })
    })

    $scope.codeMirrorOptions = {
      dragDrop : false,
      lineNumbers : true,
      lineWrapping : true
    }

    $scope.selectChart = chart => {
      if (chart == $scope.chart) return;
      $scope.model.clear();
      $scope.chart = chart;
      $scope.model = $scope.chart.model();
    }

    function refreshScroll(){
      $('[data-spy="scroll"]').each(function () {
        $(this).scrollspy('refresh');
      });
    }

    $(window).scroll(function(){

      // check for mobile
      if ($(window).width() < 760 || $('#mapping').height() < 300) return;

      var scrollTop = $(window).scrollTop() + 0,
      mappingTop = $('#mapping').offset().top + 10,
      mappingHeight = $('#mapping').height(),
      isBetween = scrollTop > mappingTop + 50 && scrollTop <= mappingTop + mappingHeight - $(".sticky").height() - 20,
      isOver = scrollTop > mappingTop + mappingHeight - $(".sticky").height() - 20,
      mappingWidth = mappingWidth ? mappingWidth : $('.mapping').width();

      if (mappingHeight-$('.dimensions-list').height() > 90) return;
      //console.log(mappingHeight-$('.dimensions-list').height())
      if (isBetween) {
        $(".sticky")
        .css("position","fixed")
        .css("width", mappingWidth+"px")
        .css("top","20px")
      }

      if(isOver) {
        $(".sticky")
        .css("position","fixed")
        .css("width", mappingWidth+"px")
        .css("top", (mappingHeight - $(".sticky").height() + 0 - scrollTop+mappingTop) + "px");
        return;
      }

      if (isBetween) return;

      $(".sticky")
      .css("position","relative")
      .css("top","")
      .css("width", "");

    })

    $scope.sortCategory = chart => {
      // sort first by category, then by title
      return [chart.category(),chart.title()];
    };

    $(document).ready(refreshScroll);
  }) //;

  .directive('jsonViewer', dataService => {
    return {
      scope : {
        json : "=",
        onSelect : "="
      },
      link: function postLink(scope, element, attrs) {
        scope.$watch('json', json => {
          update();
        })
        function update(){
          d3.select(element[0]).selectAll("*").remove();
          var tree = d3.select(element[0])
          .append("div")
          .classed("json-node","true")
          var j = scope.json;
          explore(j, tree);
          function explore(m, el){

            if ( el === tree && is.object(m) && is.not.array(m) && is.not.empty(m) ) {
              el.append("div")
              //  .classed("json-node","true")
              .text(d => {
                return "{";
              })
            }

            var n = el === tree && is.array(m) && is.not.empty(m) ? [m] : m;
            for (var c in n) {
              var cel = el.append("div")
                .datum(n[c])//d => {console.log(el === tree, n); return el === tree ? {tree:n} : n[c]})
                .classed("json-node","true")
              if ( is.array(n[c]) && is.not.empty(n[c])) {
                cel.classed("json-closed", d => { return el === tree ? "false" : "true"})
                cel.classed("json-array", d => { return el === tree ? "false" : "true"})
                //data-toggle="tooltip"
                //data-title="Clear all"
                cel.append("i")
                  .classed("json-icon fa fa-plus-square-o pull-left","true")
                  .on("click", d => {
                    d3.event.stopPropagation();
                    d3.select(this.parentNode).classed("json-closed", function(){
                      return !d3.select(this).classed("json-closed");
                    })
                    d3.select(this).classed("fa-plus-square-o", d3.select(this.parentNode).classed("json-closed"))
                    d3.select(this).classed("fa-minus-square-o", !d3.select(this.parentNode).classed("json-closed"))
                  })
              }
              cel.append("div")
                .html(d => {
                  var pre = is.array(n) ? "" : "<b>"+c + "</b> : ";
                  var text = is.array(n[c]) ? "[" : is.object(n[c]) ? "{" : n[c];
                  text += is.array(n[c]) && !n[c].length ? "]" : is.object(n[c]) && is.empty(n[c]) ? "}" : "";
                  return pre + text;
                })
              if (is.object(n[c])) explore(n[c], cel);
            }
            if (is.array(n) && el !== tree) {
              el.select('div')
                .attr("data-toggle","tooltip")
                .attr("data-title", d => {
                  return "Load " + d.length + " records";
                })
                .on("mouseover", d => {
                  d3.event.stopPropagation();
                  d3.select(this.parentNode).classed("json-hover", true)
                })
                .on("mouseout", d => {
                  d3.event.stopPropagation();
                  d3.select(this.parentNode).classed("json-hover", false)
                })
                .on("click", d => {
                  d3.event.stopPropagation();
                  scope.onSelect(d);
                })
            }
            if ( is.object(n) && is.not.empty(n) ) {
              if (is.array(n) && el === tree) return;
              el.append("div")
              //  .classed("json-node","true")
                .text(d => {
                  var text = is.array(n) ? "]" : "}";
                  return text;
                })
            }
            $('[data-toggle="tooltip"]').tooltip({animation:false});
          }

        }

      }
    };
  })
  .directive('chart', function ($rootScope, dataService) {
    console.log("ENTERED chart");
    return {
      restrict: 'A',
      link: function postLink(scope, element, attrs) {
        function update(){
          $('*[data-toggle="tooltip"]').tooltip({ container:'body' });
          d3.select(element[0]).select("*").remove();
          if (!scope.chart || !scope.data.length) return;
          if (!scope.model.isValid()) return;
          d3.select(element[0])
            .append("svg")
            .datum(scope.data)
            .call(
              scope.chart
              .on('startDrawing', function(){
                if(!scope.$$phase) {
                  scope.chart.isDrawing(true)
                  scope.$apply()
                }
              })
              .on('endDrawing', function(){
                $rootScope.$broadcast("completeGraph");
                if(!scope.$$phase) {
                  scope.chart.isDrawing(false)
                  scope.$apply()
                }
              })
            )
          scope.svgCode = d3.select(element[0])
            .select('svg')
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .node().parentNode.innerHTML;
          $rootScope.$broadcast("completeGraph");
        }
        scope.delayUpdate = dataService.debounce(update, 300, false);
        scope.$watch('chart', function(){ console.log("> chart"); update(); });
        scope.$on('update', function(){ console.log("> update"); update(); });
        //scope.$watch('data', update)
        scope.$watch(function(){ if (scope.model) return scope.model(scope.data); }, update, true);
        scope.$watch(function(){ if (scope.chart) return scope.chart.options().map(d => { return d.value }); }, scope.delayUpdate, true);
      }
    };
  })
  .directive('chartOption', function () {
    console.log("ENTERED chartOption");
    return {
      restrict: 'A',
      link: function postLink(scope, element, attrs) {
        var firstTime = false;
        element.find('.option-fit').click(function(){
          scope.$apply(fitWidth);
        });
        scope.$watch('chart', fitWidth);
        function fitWidth(chart, old){
          if (chart == old) return;
          if(!scope.option.fitToWidth || !scope.option.fitToWidth()) return;
          scope.option.value = $('.col-lg-9').width();
        }
        $(document).ready(fitWidth);
      }
    };
  })
  .directive('colors', function ($rootScope) {
    console.log("ENTERED colors");
    return {
      restrict: 'A',
      templateUrl : '/assets/templates/colors.html',
      link: function postLink(scope, element, attrs) {
        scope.scales = [
          {
            type : 'Ordinal (categories)',
            value : d3.scaleOrdinal().range(raw.divergingRange(1)),
            reset : function(domain) { this.value.range(raw.divergingRange(domain.length || 1)); },
            update : ordinalUpdate
          },
          /*{
            type : 'Ordinal (max 20 categories)',
            value : d3.scale.category20(),
            reset : function(){ this.value.range(d3.scale.category20().range().map(d => { return d; })); },
            update : ordinalUpdate
          },
          {
            type : 'Ordinal B (max 20 categories)',
            value : d3.scale.category20b(),
            reset : function(){ this.value.range(d3.scale.category20b().range().map(d => { return d; })); },
            update : ordinalUpdate
          },
          {
            type : 'Ordinal C (max 20 categories)',
            value : d3.scale.category20c(),
            reset : function(){ this.value.range(d3.scale.category20c().range().map(d => { return d; })); },
            update : ordinalUpdate
          },
          {
            type : 'Ordinal (max 10 categories)',
            value : d3.scale.category10(),
            reset : function(){ this.value.range(d3.scale.category10().range().map(d => { return d; })); },
            update : ordinalUpdate
          },*/
          {
            type : 'Linear (numeric)',
            value : d3.scaleLinear().range(["#f7fbff", "#08306b"]),
            reset : function(){ this.value.range(["#f7fbff", "#08306b"]); },
            update : linearUpdate
          }
        ];
        function ordinalUpdate(domain) {
          if (!domain.length) domain = [null];
          this.value.domain(domain);
          listColors();
        }
        function linearUpdate(domain) {
          domain = d3.extent(domain, d => {return +d; });
          if (domain[0]==domain[1]) domain = [null];
          this.value.domain(domain).interpolate(d3.interpolateLab);
          listColors();
        }
        scope.setScale = function(){
          scope.option.value = scope.colorScale.value;
          scope.colorScale.reset(scope.colorScale.value.domain());
          $rootScope.$broadcast("update");
        }
        function addListener(){
          scope.colorScale.reset(scope.colorScale.value.domain());
          scope.option.on('change', domain => {
            scope.option.value = scope.colorScale.value;
            scope.colorScale.update(domain);
          })
        }
        scope.colorScale = scope.scales[0];
        scope.$watch('chart', addListener)
        scope.$watch('colorScale.value.domain()', domain => {
          scope.colorScale.reset(domain);
          listColors();
        }, true);
        function listColors(){
          scope.colors = scope.colorScale.value.domain().map(d => {
            return { key: d, value: d3.color(scope.colorScale.value(d)).hex() }
          }).sort(function (a,b){
            if (raw.isNumber(a.key) && raw.isNumber(b.key)) return a.key - b.key;
            return a.key < b.key ? -1 : a.key > b.key ? 1 : 0;
          })
        }
        scope.setColor = function(key, color) {
          var domain = scope.colorScale.value.domain(),
          index = domain.indexOf(key),
          range = scope.colorScale.value.range();
          range[index] = color;
          scope.option.value.range(range);
          $rootScope.$broadcast("update");
        }
        scope.foreground = color => {
          return d3.hsl(color).l > .5 ? "#000000" : "#ffffff";
        }
        scope.$watch('option.value', value => {
          if(!value) scope.setScale();
        })
      }
    };
  })
  .directive('sortable', function($rootScope) {
    console.log("ENTERED sortable");
    return {
      restrict: 'A',
      scope : {
        title : "=",
        value : "=",
        types : "=",
        multiple : "="
      },
      template:'<div class="msg">{{messageText}}</div>',
      link: function postLink(scope, element, attrs) {
        var removeLast = false;
        element.sortable({
          items : '> li',
          connectWith: '.dimensions-container',
          placeholder:'drop',
          start: onStart,
          update: onUpdate,
          receive : onReceive,
          remove: onRemove,
          over: over,
          tolerance:'intersect'
        })
        function over(e,ui){
          var dimension = ui.item.data().dimension,
          html = isValidType(dimension) ? '<i class="fa fa-arrow-circle-down breath-right"></i>Drop here' : '<i class="fa fa-times-circle breath-right"></i>Don\'t drop here'
          element.find('.drop').html(html);
        }
        function onStart(e,ui){
          var dimension = ui.item.data().dimension,
          html = isValidType(dimension) ? '<i class="fa fa-arrow-circle-down breath-right"></i>Drop here' : '<i class="fa fa-times-circle breath-right"></i>Don\'t drop here'
          element.find('.drop').html(html);
          element.parent().css("overflow","visible");
          angular.element(element).scope().open=false;
        }
        function onUpdate(e,ui){
          ui.item.find('.dimension-icon').remove();
          if (ui.item.find('span.remove').length == 0) {
            ui.item.append("<span class='remove pull-right'>&times;</span>")
          }
          ui.item.find('span.remove').click(function(){  ui.item.remove(); onRemove(); });
          if (removeLast) {
            ui.item.remove();
            removeLast = false;
          }
          scope.value = values();
          scope.$apply();
          element.parent().css("overflow","hidden");
          var dimension = ui.item.data().dimension;
          ui.item.toggleClass("invalid", !isValidType(dimension))
          message();
          $rootScope.$broadcast("update");
        }
        scope.$watch('value', value => {
          if (!value.length) {
            element.find('li').remove();
          }
          message();
        })
        function onReceive(e,ui) {
          var dimension = ui.item.data().dimension;
          removeLast = hasValue(dimension);
          if (!scope.multiple && scope.value.length) {
            var found = false;
            element.find('li').each(function (i,d) {
              if ($(d).data().dimension.key == scope.value[0].key && !found) {
                $(d).remove();
                found = true;
                removeLast=false;
              }
            })
          }
          scope.value = values();
          ui.item.find('span.remove').click(function(){  ui.item.remove(); onRemove(); })
        }
        function onRemove(e,ui) {
          scope.value = values();
          scope.$apply();
          $rootScope.$broadcast("update");
        }
        function values(){
          if (!element.find('li').length) return [];
          var v = [];
          element.find('li').map(function (i,d){
            v.push($(d).data().dimension);
          })
          return v;
        }
        function hasValue(dimension){
          for (var i=0; i<scope.value.length;  i++) {
            if (scope.value[i].key == dimension.key) {
              return true;
            }
          }
          return false;
        }
        function isValidType(dimension) {
          if (!dimension) return;
          return scope.types.map(d => { return d.name; }).indexOf(dimension.type) != -1;
        }
        function message(){
          var hasInvalidType = values().filter(d => { return !isValidType(d); }).length > 0;
          scope.messageText = hasInvalidType
          ? "You should only use " + scope.types.map(d => { return d.name.toLowerCase() + "s"; }).join(" or ") + " here"
          : "Drag " + scope.types.map(d => { return d.name.toLowerCase() + "s"; }).join(", ") + " here";
                      //element.parent().find('.msg').html(messageText);
        }
      }
    }
  })
  .directive('draggable', function () {
    return {
      restrict: 'A',
      scope:false,
      //  templateUrl : '/assets/templates/dimensions.html',
      link: function postLink(scope, element, attrs) {
        scope.$watch('metadata', metadata => {
          if(metadata && !metadata.length) element.find('li').remove();
          element.find('li').draggable({
            connectToSortable:'.dimensions-container',
            helper : 'clone',
            revert: 'invalid',
            start : onStart,
            containment: "document"
          })
        })
        function onStart(e, ui) {
          ui.helper.addClass("dropped");
          ui.helper.css('z-index','100000');
        }
      }
    }
  })
  .directive('group', function () {
    return {
      restrict: 'A',
      link: function postLink(scope, element, attrs) {
        scope.$watch(attrs.watch, watch => {
          var last = element;
          element.children().each(function(i, o){
            if( (i) && (i) % attrs.every == 0) {
              var oldLast = last;
              last = element.clone().empty();
              last.insertAfter(oldLast);
            }
            $(o).appendTo(last)
          })
        },true)
      }
    };
  })
  .directive('rawTable', function () {
    return {
      restrict: 'A',
      link: function postLink(scope, element, attrs) {
        var sortBy,
        descending = true;
        function update(){
          d3.select(element[0]).selectAll("*").remove();
          if(!scope.data|| !scope.data.length) {
            d3.select(element[0]).append("span").text("Please, review your data")
            return;
          }
          var table = d3.select(element[0])
          .append('table')
          .attr("class","table table-striped table-condensed")
          if (!sortBy) sortBy = scope.metadata[0].key;
          var headers = table.append("thead")
          .append("tr")
          .selectAll("th")
          .data(scope.metadata)
          .enter().append("th")
          .text( d => { return d.key; } )
          .on('click', d => {
            descending = sortBy == d.key ? !descending : descending;
            sortBy = d.key;
            update();
          })
          headers.append("i")
          .attr("class", d => { return descending ? "fa fa-sort-desc pull-right" : "fa fa-sort-asc pull-right"})
          .style("opacity", d => { return d.key == sortBy ? 1 : 0; })
          var rows = table.append("tbody")
          .selectAll("tr")
          .data(scope.data.sort(sort))
          .enter().append("tr");
          var cells = rows.selectAll("td")
          .data(d3.values)
          .enter().append("td");
          cells.text(String);
        }
        function sort(a,b) {
          if (raw.isNumber(a[sortBy]) && raw.isNumber(b[sortBy])) return descending ? a[sortBy] - b[sortBy] : b[sortBy] - a[sortBy];
          return descending ? a[sortBy] < b[sortBy] ? -1 : a[sortBy] > b[sortBy] ? 1 : 0 : a[sortBy] < b[sortBy] ? 1 : a[sortBy] > b[sortBy] ? -1 : 0;
        }
        scope.$watch('data', update);
        scope.$watch('metadata', function(){
          sortBy = null;
          update();
        });
      }
    };
  })
  .directive('copyButton', function () {
    return {
      restrict: 'A',
      link: function postLink(scope, element, attrs) {
        var client = new ZeroClipboard(element);
        client.on("ready", readyEvent => {
          client.on('aftercopy', function(event) {
            element.trigger("mouseout");
            setTimeout(function () {
              element.tooltip({ title: 'Copied' });
              element.tooltip('show');
            }, 150);
          });
        });
        element.on('mouseover', function(client, args) {
          element.tooltip('destroy');
          element.tooltip({ title: 'Copy to clipboard' });
          element.tooltip('show');
        });
        element.on('mouseout', function(client, args) {
          element.tooltip('destroy');
        });
      }
    };
  })
  .directive('coder', function () {
    return {
      restrict: 'EA',
      template :  '<textarea id="source" readonly class="source-area" rows="4" ng-model="svgCode"></textarea>',
      link: function postLink(scope, element, attrs) {
        scope.$on('completeGraph',function(){
          var svgCode = d3.select('#chart > svg')
          .attr("version", 1.1)
          .attr("xmlns", "http://www.w3.org/2000/svg")
          .node().parentNode.innerHTML;
          element.find('textarea').val(svgCode)
        })
        /*function asHTML(){
          if (!$('#chart > svg').length) return "";
          return d3.select('#chart > svg')
              .attr("xmlns", "http://www.w3.org/2000/svg")
              .node().parentNode.innerHTML;
        }
        scope.$watch(asHTML, function(){
          scope.html = asHTML();
        },true)
        scope.$on('update', function(){
          scope.html = asHTML();
        })*/
      }
    };
  })
  .directive('downloader', function () {
    return {
      restrict: 'E',
      replace:true,
      template :  '<div class="row">' +
      '<form class="form-search col-lg-12">' +
      '<button bs-select class="btn btn-default" placeholder="Choose type" ng-model="mode" bs-options="m.label for m in modes">' +
      'Select <span class="caret"></span>' +
      '</button>' +
      '<input class="form-control col-lg-12" placeholder="Filename" type="text" ng-model="filename">' +
      '<button class="btn btn-success form-control" ng-class="{disabled:!mode.label}" ng-click="mode.download()">Download</button>' +
      '</form>' +
      '</div>',
      link: function postLink(scope, element, attrs) {
        var source = "#chart > svg";
        var getBlob = function() {
          return window.Blob || window.WebKitBlob || window.MozBlob;
        }
        // Removing HTML entities from svg
        function decodeHtml(html) {
          /*var txt = document.createElement("textarea");
          txt.innerHTML = html;
          return txt.value;*/
          return html.replace(/[\u00A0-\u9999<>\&]/gim, function(i) {
           return '&#'+i.charCodeAt(0)+';';
         });
        }
        function downloadSvg(){
          var BB = getBlob();
          var html = d3.select(source)
            .attr("version", 1.1)
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .node().parentNode.innerHTML;
          //html = he.encode(html);
          var isSafari = (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Chrome') == -1);
          if (isSafari) {
            var img = "data:image/svg+xml;utf8," + html;
            var newWindow = window.open(img, 'download');
          } else {
            var blob = new BB([html], { type: "data:image/svg+xml" });
            saveAs(blob, (element.find('input').val() || element.find('input').attr("placeholder")) + ".svg")
          }
        }
        function downloadPng() {
          var content = d3.select("body").append("canvas")
          .attr("id", "canvas")
          .style("display", "none")
          var html = d3.select(source)
          .node().parentNode.innerHTML;
          var image = new Image;
          image.src = 'data:image/svg+xml;base64,' + window.btoa(unescape(encodeURIComponent(html)));
          var canvas = document.getElementById("canvas");
          var context = canvas.getContext("2d");
          image.onload = function() {
            canvas.width = image.width;
            canvas.height = image.height;
            context.drawImage(image, 0, 0);
            var isSafari = (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Chrome') == -1);
            if (isSafari) {
              var img = canvas.toDataURL("image/png;base64");
              var newWindow = window.open(img, 'download');
              window.location = img;
            } else {
              var a = document.createElement("a");
              a.download = (scope.filename || element.find('input').attr("placeholder")) + ".png";
              a.href = canvas.toDataURL("image/png;base64");
              var event = document.createEvent("MouseEvents");
              event.initMouseEvent(
                "click", true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
                );
              a.dispatchEvent(event);
            }
          };
          d3.select("#canvas").remove();
        }
        var downloadData = function() {
          var json = JSON.stringify(scope.model(scope.data));
          var blob = new Blob([json], { type: "data:text/json;charset=utf-8" });
          saveAs(blob, (scope.filename || element.find('input').attr("placeholder")) + ".json")
        }
        scope.modes = [
          { label : 'Vector graphics (svg)', download : downloadSvg },
          { label : 'Image (png)', download : downloadPng },
          { label : 'Data model (json)', download : downloadData }
        ]
        //scope.mode = scope.modes[0]
      }
    };
  }) //;

  .filter('categoryFilter', [function () {
      return function (charts, category) {
            return charts.filter(function (chart){
              return !chart.category() && category == 'Others' || chart.category() == category;
            });
      };
  }])

  .filter('decodeUrl', [function () {
      return function (url) {
        if (!url) return url;
        return decodeURIComponent(url);
      };
  }]);
