'use strict';

angular.module('demoApp')
  .controller('AdhocWizardTypeQueryCtrl', function ($state,$scope, $http, $stateParams, $sce, $interval, databaseService, wizardService) {

    $scope.uploadButtonActive = false;
    $scope.message = "";
    $scope.messageClass = "form-group";
    $scope.searchTypeCollectionName="collectionName";
    $scope.searchTypeDirectory="directory";
    $scope.searchTypeRootName="rootName";
    $scope.searchTypePartialUri="partialUri";
    $scope.searchTypeDescription={ };
    $scope.searchTypeDescription[$scope.searchTypeCollectionName]={title:"Collection name",message:"Please enter a collection name!"};
    $scope.searchTypeDescription[$scope.searchTypeDirectory]={title:"Directory name",message:"Please enter Directory name to search"};
    $scope.searchTypeDescription[$scope.searchTypeRootName]= {title:"Root Element Name",message: ""};
    $scope.searchTypeDescription[$scope.searchTypePartialUri] ={title:"URI",message:"Enter partial uri (wildcard pattern) or a complete URI"};
    $scope.noResultsMessage="";
    $scope.inputField = {};
    $scope.formInput = {};
    $scope.formInput.searchString = '';
    $scope.searchType = '';
    $scope.uris=[];
    $scope.doc={text:"",type:"",uri:""};
    $scope.rootElements = [];
    $scope.urisStack=[];

    $scope.filename = '';
    $scope.fileType = 0;

    $scope.wizardUploadFormData = null;

    databaseService.list().then(function(data) {
          $scope.availableDatabases = data;
    });
    $scope.$watch('docTypeMethod', function() {
        $scope.message = "";
    });

      $scope.$watch('formInput.selectedDatabase', function(value) {
          if ($scope.docTypeMethod !== 'select' || !value) {
              return;
          }
          wizardService.listDocTypes(value).then(function(docTypes) {
              $scope.availableDocTypes = docTypes || [];
              var error = _.isEmpty(docTypes);
              $scope.message = error ?
                  "Could not find any available document types.  Perhaps it contains no documents or you currently have insufficient permissions to read them."
                  : "";
          });
      });

    $scope.resetSelectedDoc=function(){$scope.doc={text:"",type:"",uri:""}};
    $scope.openDocSelectionModal=function(searchType){
    		$scope.uris=[]
    		$scope.searchType=searchType;
    		$scope.resetSelectedDoc();
    		$scope.formInput.searchString="";
    		$scope.noResultsMessage="Please enter search criteria and click search.";
    		$http.get('/api/adhoc', {}, {
            withCredentials: true,
            headers: {'Content-Type': undefined },
            transformRequest: angular.identity
        }).success(function(data, status){
            if (status == 200){
                $scope.wizardForm = {databases:data};
            		$("#selectDocument").modal();
            }
        }).error(function(err){
           console.log(err);
           $scope.message = "An error occurred. Check the browser console log for details.";
           $scope.messageClass = "form-group has-error";
         });
    };
    $scope.next=function(){  $scope.searchDocuments("","next");};
    $scope.prev=function(){  $scope.searchDocuments("","prev");};
    
    $scope.searchDocuments=function(docUri,nav){
    		$scope.doc={text:"",type:"",uri:docUri}
    		var params = new FormData();
		params.append("database",$scope.formInput.selectedDatabase);
		params.append( "docUri" ,docUri?docUri:"");
		params.append("collectionName" ,$scope.searchType == $scope.searchTypeCollectionName?$scope.formInput.searchString:"");
		params.append("directory", $scope.searchType == $scope.searchTypeDirectory?$scope.formInput.searchString:"");
		params.append("rootElementName", $scope.searchType == $scope.searchTypeRootName?$scope.formInput.searchString:"");
		params.append("partialUri", $scope.searchType == $scope.searchTypePartialUri?$scope.formInput.searchString:"");
		if($scope.urisStack && $scope.urisStack.length>0){
    			if(nav == "next"){
        			params.append("startUri", $scope.urisStack[($scope.urisStack.length - 1)])
        		}
        		else if(nav == "prev"){
        			$scope.urisStack.pop()
        			params.append("startUri", $scope.urisStack.length>0?$scope.urisStack.pop():"");
        		}
        		else{
        			//new search
        			$scope.urisStack=[];
        			params.append("startUri", "")
        		}
    		}
		
		$http.post('/api/wizard/documentSelection', params, {
            withCredentials: true,
            headers: {'Content-Type': undefined },
            transformRequest: angular.identity            
        }).success(function(data, status,headers){
            if (status == 200){
                if(docUri){
                		var contentType=headers("content-type")
                		if ( contentType.includes("application/json")) {
				        $scope.doc.text = vkbeautify.json(data);
				        $scope.doc.type = "application/json";
				        
				      } else if ( contentType.includes("application/xml")) {
				    	  	$scope.doc.text = vkbeautify.xml(data);
				    	  	$scope.doc.type = "application/xml";
				      } 
				      else{
				    	  	//do nothing
				      }
                }
                else{
                		$scope.uris=data.results   
                		if($scope.searchType == $scope.searchTypePartialUri){
                			var maxIndex=0
                			if($scope.urisStack.length>0)
                			{
                				maxIndex=$scope.urisStack[$scope.urisStack.length-1]
                			}
                			var newMax=parseInt(maxIndex)+$scope.uris.length
                			$scope.urisStack.push(newMax);                    		                			
                		}
                		else{
                			$scope.urisStack.push($scope.uris[($scope.uris.length - 1)])
                		}
                		$scope.noResultsMessage="No results found";
                }                
            }
        }).error(function(err){
           console.log(err);
           $scope.message = "An error occurred. Check the browser console log for details.";
           $scope.messageClass = "form-group has-error";
         });
    };
    $scope.$watch('formInput.selectedDatabase', function(newValue) {
        if($scope.searchType == $scope.searchTypeRootName) {
        		$scope.rootElements = [];
          	var params = new FormData();
	  		params.append("database",newValue);
	  		
	  		$http.post('/api/wizard/documentSelection', params, {
	              withCredentials: true,
	              headers: {'Content-Type': undefined },
	              transformRequest: angular.identity            
	          }).success(function(data, status){
	              if (status == 200){
	                  $scope.rootElements = _.map(data.results, function(inp) {
	                      var split = inp.split("~")
                          var newValue = ""
                          if ( split.length > 1 && split[1].trim().length>0) {
	                          newValue = split.join(" - ")
                          } else
                              newValue = split[0]
                          return {key:inp,value:newValue}
                      });
	              }
	          }).error(function(err){
	             console.log(err);
	             $scope.message = "An error occurred. Check the browser console log for details.";
	             $scope.messageClass = "form-group has-error";
	           });
        }
    });
    $scope.selectDocument = function() {
		$scope.filename = $scope.doc.uri;
        $scope.wizardUploadFormData = new FormData();
        //Take the first selected file
        var fileMimeType = $scope.doc.type;
        if ( !isSupportedFileType(fileMimeType) ) {
            $scope.message = "This file-type is not supported. Choose a different file.";
            $scope.uploadButtonActive = false;
            $scope.messageClass = "form-group has-error";
        } else {
            $scope.message = "Select the desired mode and press the create button";
            $scope.wizardUploadFormData.append("uploadedDoc", $scope.doc.text);
            $scope.wizardUploadFormData.append("mimeType", fileMimeType);
            $scope.messageClass = "form-group"
            $scope.uploadButtonActive = true;
            $scope.resetSelectedDoc();
            $("#selectDocument").modal("hide"); 
        }
    };
    
    $scope.changeFile = function(files) {
        if (files.length > 0){
        	// kind of hacky, but the event wasn't triggering a digest cycle so the 
        	// screen wasn't updated with the file name
        	$interval(function() {
            	$scope.filename = files[0].name;
        	},300, 1);

            //Take the first selected file
            var fileMimeType = files[0]['type'];

            $scope.wizardUploadFormData = new FormData();
            $scope.message = 'Validating file structure...';
            $scope.uploadButtonActive = false;

            // Read the file and make sure we can parse it as JSON or XML
            var fileReadError = false;
            var reader = new FileReader();
            reader.onload = function(e) {
                // Do nothing until the file is loaded.
                if (e.target.readyState !=2) {
                    return;
                }
                
                if(e.target.error) {
                    $scope.message = 'Unable to read the file.';
                } else {
                    var content = e.target.result;
                    if (getFileType(fileMimeType) === 0) {
                        // Validate XML
                        var parser = new DOMParser();
                        var xmlDoc = parser.parseFromString(content, 'text/xml');
                        if(!xmlDoc) {
                            $scope.message = 'Unable to parse the file as XML.';
                        } else if (xmlDoc.getElementsByTagName('parsererror').length) {
                            $scope.message = 'UNABLE TO PARSE XML: ' + xmlDoc.getElementsByTagName('parsererror')[0].innerText;
                        }
                    } else {
                        // Validate JSON
                        try {
                            JSON.parse(content)
                        } catch(e) {
                            $scope.message = 'UNABLE TO PARSE JSON: ' + e.message;
                        }
                    }
                }

                // If we havent set an error message, then the file is valid.
                if($scope.message === 'Validating file structure...') {
                    $scope.message = '';
                    $scope.wizardUploadFormData.append("uploadedDoc", files[0]);
                    $scope.wizardUploadFormData.append("mimeType", files[0]['type']);
                    $scope.uploadButtonActive = true;
                }
            }

            if ( !isSupportedFileType(fileMimeType) ) {
                $scope.message = "This file type is not supported. Please choose a different file.";
            } else {
                reader.readAsText(files[0]);
            }
        }
        else
        {
            $scope.wizardUploadFormData = null;
            $scope.uploadButtonActive = false;
        }

    };

    $scope.selectDocumentType = function() {
        if ($scope.docTypeMethod === 'upload') {
            $scope.upload();
        }
        else if ($scope.docTypeMethod === 'select') {
            $scope.sample();
        }
    };

    function prepareStep2(data) {
        $scope.wizardForm = data;
        for(var index = 0; index < data.fields.length; index++){ 
            data.fields[index].include = false;
            data.fields[index].includeMode = "none";
            data.fields[index].defaultTitle = createTitle(data.fields[index].elementName);
        }
        $state.go('adhoc-wizard-field-selection', {deparams:
                {formData: data,
                backState: "adhoc-wizard",
                queryView: "query"}})

    }

      function createTitle(suggestedName){
          var namespaceDelimPos = suggestedName.indexOf(":");
          if(namespaceDelimPos != -1){
              return suggestedName.substr(namespaceDelimPos+1);
          }

          return suggestedName;
      }

    $scope.sample = function() {
        var database = $scope.formInput.selectedDatabase;
        var docType = $scope.formInput.startingDocType;
        wizardService.sampleDocType(database, docType.ns, docType.localName, $scope.queryView)
        .success(function(data, status) {
            if (status == 200) {
                prepareStep2(data);
            }
        }).error(function(err){
           console.log(err);
           $scope.message = "An error occurred. Check the browser console log for details.";
           $scope.messageClass = "form-group has-error";
         });
    };

    $scope.upload = function(){
        if ($scope.wizardUploadFormData == null){
            $scope.message = 'Please choose a file using the browse button.';
            return;
        }
        $scope.wizardUploadFormData.append('type',$scope.queryView);
        var fileMimeType = $scope.wizardUploadFormData.get('mimeType');
        $scope.isNamespaceAware = isNamespaceAwareMimeType(fileMimeType)
        $scope.fileType = getFileType(fileMimeType)
        if ( !isSupportedFileType(fileMimeType) ) {
              $scope.message = "This file-type is not supported. Choose a different file";
              $scope.uploadButtonActive = false;
        } else {
            $http.post('/api/wizard/upload', $scope.wizardUploadFormData, {
                withCredentials: true,
                headers: {'Content-Type': undefined },
                transformRequest: angular.identity
            }).success(function(data, status){
                if (status == 200) {
                    prepareStep2(data);
                }
            }).error(function(err){
               console.log(err);
               $scope.message = "An error occurred. Check the browser console log for details.";
               $scope.messageClass = "form-group has-error";
             });
        }
    };

    $scope.back = function() {
            $state.go('crud', {});
    };
  });

function getFileType(mimeType) {
    if ( mimeType === "text/xml" || mimeType == "application/xml" ) {
       return 0;
    } else if ( mimeType == "application/json" ) {
           return 1;
    }
    return -1;
}
function isNamespaceAwareMimeType(mimeType) {
    return getFileType(mimeType) == 0;
}

function isSupportedFileType(mimeType) {
    return getFileType(mimeType) >= 0;
};