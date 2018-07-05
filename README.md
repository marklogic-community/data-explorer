
# MarkLogic Data Explorer (Ferret)

This is a tool to **quickly and easily set up queries and tabular views** of data in any MarkLogic database. It is currently limited to XML data, but other data models are in the works.

The guiding principle of Data Explorer is to separate the roles between *a data owner* who knows the data and manages lists of queries and views, and *data users* who simply need to query, view, explore and export data.

All data is exposed thorugh tabular HTML views and tabular Excel outputs (.csv format).

The tool is **non-intrusive** and **easy to install**, meaning that you can download and run an install quickly without impacting your existing databases or configuration. Data Explorer will set up an extra modules and configuration database, but will not store or modify data in your own databases.

----
## Can I use Data Explorer?

Data Explorer is appropriate for any project with XML data in the database. JSON, RDF, SQL and other access is on the way.

### System Requirements

- MarkLogic 8.0-2 or greater [(ML9)](https://developer.marklogic.com/products) [(ML8)](https://developer.marklogic.com/products/marklogic-server/8.0)
- Java 8 JDK or greater [(Java 8)](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- Gradle 3.1 or greater [(Gradle)](https://gradle.org/gradle-download/)

Data Explorer downloads: https://github.com/marklogic-community/data-explorer/releases

----
## Setup and Use Overview
Most of the setup is self explanatory. Follow these steps to get views on your (existing) data fast:
* Download the data-explorer.jar from the releases area (don't download or checkout all the source code)
* run 
   * java -jar data-explorer.jar deploy
* browse to localhost:7777 and login as wizard-user 
   * The deploy step created two users, "wizard-user" and "search-user" both with password = "password". Recommendation: change those passwords.
* Configure your first query:
   * upload a sample document to tell Data Explorer what elements are possible
   * Choose fields for query and view, respectively
   * Name the query/view combo and set the database where it applies
* Update/create a user or users to have both a data-explorer role, "data-explorer-search-role", and whatever role(s) needed to access data in your DB.
   * Data Explorer explicitly checks for wizard and search roles, so even the admin user will not work without a role.
* go to the "search" tab or log out and log back in as the "search-user" to see your data

**THAT'S IT** Start searching.

More details below, including pictures and some variants or advanced topics.

----
##  Setup Instructions

### Install Data Explorer into MarkLogic 
The easiest way to install and run Data Explorer is to download the auto-installer jar from the Builds section of this github site, and run with the "deploy" option.

```
java -jar data-explorer.jar deploy
```

This sets it up as a web application that runs directly out of MarkLogic. Just browse to localhost:7777 to access Data Explorer.

This shows the new databases, forests and app server that should be installed after your run the deploy command.

![Installed Artifacts Image](docImages/DataExplorerInstallResult.png?raw=true "Installed MarkLogic Items")

... Note that if you do not have a common configuraiton with your marklogic server on "localhost" with username/password of admin/admin, you'll have to modify the following parameters on the command line
java -DmlPassword=<your-admin-pwd> -DmlHost=<your-ml-host> -jar data-explorer.jar deploy 

### Set up Queries and Views

Queries and Views can only be created by a user with data-explorer-wizard-role (see Security).
With the wizard role, the "Edit config" menu item will be visible.  This capability allows management of queries and bookmarks.

**When starting the Data Explorer for the first time, there are not queries defined!!!**
Select the "Edit config" menu item to define queries.
Because you have no query views, you'll get dropped right into the "wizard" to create new queries and views when you browse to <ml-host>:7777. 

#### What is this Query/View concept?
The Data Explorer allows a users to search and view their data!  
The search can be a word/text search across all fields, or a specific elements/attributes search defined in the query.
The output (or View) provides a tabular view of the results of the search performed.

#### Defining a query
The Data Explorer has several options for defining a query.
- Choose a representative XML/JSON file from the file system
- Sample the database by collection name, directory, URI, or root element
- Sample the database by choosing a document type (this does a sampling of documents to choose from)

Once you have selected a document via one of these techniques, **click "Select fields"**


![Query Wizard Image](docImages/QueryViewWizard.png?raw=true "Query Wizard")


In the resulting wizard you must
- Name the query
- Choose the root element (this allows envelop selection)
- Tell Data Explorer which database this query and view are valid for
- Identify if you would like a bookmark and name it
- Specify the result element order as alphabetical or document order
- Specify which elements are used for queries or views or both

Save the query and go search!!!

----
## Additional Information

### Security 

There are two Data explorer roles: wizard role (data-explorer-wizard-role) and search role (data-explorer-search-role).  
**To user the Data Explorer, they must be assigned one of these roles!!!**
The wizard role is to configure queries for search role users.  This will generally be someone who has knowledge of MarkLogic and the data domain.
Search users typically do **not** have the wizard role, but rather have the data-explorer-search-role. This role allows them to see queries and views on the "search" tab. 
Users **also need permissions for your database** so either add your project's roles to search-user, or add data-explorer-search-role to a user to enable searching.

#### Default Users
A default user with name search-user and password "password" will be configured on install. 
Recommend removing default users or changing their passwords!!!

### Also add your own security roles 
A user cannot see data in the main database (your database, not the Data Explorer database) without roles that allow them to see it. So users will need roles from your existing security configuration to see data as well.

Alternatively, if users are already configured as MarkLogic Users in some way, and can see certain data, you can simply add teh data-explorer-search-role to their existing user record to enable them to use the tool *and* see their data.

### Basic searching

The left hand side has selection and query controls to find data and show in your configured view(s).
Version 0.10 has added bookmarks wich allow quick access to "saved" queries.

![Search Screen Image](docImages/SearchScreen.png?raw=true "Search Screen")

### Other featuers
In addition, the data can be
- Exported to Excel
- clicked into to see a hierarchical view of the data
    - in this view, element names are tokenized to text prompts and XML nesting becomes simple indentaiton
- click through the heirarchical view to the raw data
- view properties and collections of records

----
# Use with the Data Hub Framework or Entity Services

Out of the box, Data Explorer assumes that your documents are of different types distinguished by their root element name. If you are using the Data Hub Framework or Entity Services, however, all your documents will have the same <es:envelope> "Root Element,"" so choose a new Root Element on the Query Wizard screen. Your ideal root is probably an element inside <es:instance> that distinguishes a category or type of document.

This is not critical, but for queries to work right, you typically want them restricted to the right "type" of entity or document. 

![Root Element Selection Image](docImages/ChooseRootElement.png?raw=true "Root Element selection on the Query Wizard")

----
# Contributing, Issues and Code

## Development 
The Github repository for issue and sprint tracking is here: https://github.com/marklogic-community/data-explorer. 


## Licenses
1. MarkLogic - See [LICENSE.txt](LICENSE.txt) file
1. Saxon XSLT - This tool uses the Saxon XSLT and XQuery Processor from Saxonica Limited -  http://www.saxonica.com/
1. ANTLR Parser - See notice in [LICENSE.txt](LICENSE.txt) file
1. Licenses for individual UI Components are under [app/client/bower_components]([app/client/bower_components) in their respective directory
1. See [Notice.docx](Notice.docx) for full list of licenses

## DownloadLinks

-  [(download ML9)](https://developer.marklogic.com/products) [(install guide)](https://docs.marklogic.com/guide/installation)
    - [(download ML8)](https://developer.marklogic.com/products/marklogic-server/8.0)
- [(download Java 8)](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- [(Gradle)](https://gradle.org/gradle-download/)

## Troubleshooting
- if you get no results, be sure your user has a role that allows you to see the data. Log in as "admin" and use the Data Explorer tool to see 
the permissions on the results (click through to a row to see permissions).
- _"No database with identifier 18212714155313180665"_
    * Clear out (remove) the amps that reference the database with the database identifier
- _"Invalid parameter: Port 7777 is in use."_  
    * Find what is using that port, and change it via the --mlRestPort option to the .jar deployer, or modify gradle.properties to specify 
      another port (see ml-gradle github for details). 
- No search tab, and/or no wizard tab. - Likely need security roles added to the current user - even admin needs a role for these tabs to be visible on the UI.

