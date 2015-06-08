title: Db Migration Solutions for Java Project
date: 2015-01-25 23:58:16
category: agile
tags: [java,db,migration]
---

	
###说在前面

说起DB Migration, 用过Rails的看官必然能够回味起rake db:migrate的优雅，是的，如果我只个纯粹的Rails程序员，那就没这篇文章什么事了，可惜，我还需要写Java项目来混饭吃，没办法，那就只能在Java的世界里寻找能做同样事情的工具。一顿Google和StackOverflow之后，着实吓了我一跳，出现了一个长长的列表，Java的世界就是能把一件简单的事情搞得如此复杂，那我就得开始整理一下思路，为项目选择一个合适的db migration工具。<!--more-->

	Flyway
	Liquibase
	c5-db-migration
	dbdeploy
	mybatis
	MIGRATEdb
	migrate4j
	dbmaintain
	AutoPatch

###Comparison Matrix
![Comparison Matrix](/img/db-migration-solution-comparison-matrix.png)

###Criteria
	   1. can migrate up
	   2. can migrate down
	   3. support SQL as migration file
	   4. easy to use
	   5. support existing database

经过各方面比较，mybatis-migration是我认为比较合适的方案，文档齐全，易于使用，功能恰到好处。其实flyway我也有看中，可惜不支持rollback让我很是纠结，最终决定选择mybatis-migration。接下来就来简单试用一下吧。

###Practise

####Step 1: Installation
Download from https://github.com/mybatis/migrations/releases, 
then install it referring to http://mybatis.github.io/migrations/installation.html.

####Step 2: Create DataBase
```shell
$ mysqladmin -uroot -pcepmmon create migrate-testdb 
```
####Step 3: Generate init files
```shell
$ migrate init
```
	-- MyBatis Migrations - init
	Initializing: .
	Creating: environments
	Creating: scripts
	Creating: drivers
	Creating: README
	Creating: development.properties
	Creating: bootstrap.sql
	Creating: 20150125143145_create_changelog.sql
	Creating: 20150125143146_first_migration.sql
	Done!
	
	-- MyBatis Migrations SUCCESS
	-- Total time: 2s
	-- Finished at: Sun Jan 25 22:31:46 CST 2015
	-- Final Memory: 2M/480M

```shell
$ tree
```
	.
	├── README
	├── drivers
	│   └── mysql-connector-java-3.1.6-bin.jar
	├── environments
	│   └── development.properties
	└── scripts
	    ├── 20150125143145_create_changelog.sql
	    ├── 20150125143146_first_migration.sql
	    └── bootstrap.sql
	
	3 directories, 6 files


####Step 4: Migration Status
```shell
$ migrate status 
```
	-- MyBatis Migrations - status
	20150125143145    ...pending...    create changelog
	20150125143146    ...pending...    first migration
	
	-- MyBatis Migrations SUCCESS
	-- Total time: 0s
	-- Finished at: Sun Jan 25 23:00:39 CST 2015
	-- Final Memory: 7M/480M

####Step 5: Migrate db up to latest revision
```shell
$ cat scripts/20150125143145_create_changelog.sql 
```     
                                                                                                                                   
	-- // Create Changelog
	
	-- Default DDL for changelog table that will keep
	-- a record of the migrations that have been run.
	
	-- You can modify this to suit your database before
	-- running your first migration.
	
	-- Be sure that ID and DESCRIPTION fields exist in
	-- BigInteger and String compatible fields respectively.
	
	CREATE TABLE ${changelog} (
		id numeric(20,0) NOT NULL,
		APPLIED_AT VARCHAR(255) NOT NULL,
		DESCRIPTION VARCHAR(255) NOT NULL,
		PRIMARY KEY (id)
	);

	-- //@UNDO	
	DROP TABLE ${change log};

```shell
$ cat scripts/20150125143146_first_migration.sql 
```                                                                                                                                  
	-- // First migration.
	-- Migration SQL that makes the change goes here.
	create table users (
	  id int not null,
	  name varchar(255),
	  primary key(id)
	);
	
	-- //@UNDO
	-- SQL to undo the change goes here.
	drop table users;

```shell
$ migrate up
``` 
	---------------------------------------------------------
	-- MyBatis Migrations - up 
	========== Applying: 20150125143145_create_changelog.sql 
	========== Applying: 20150125143146_first_migration.sql 
	---------------------------------------------------------
	-- MyBatis Migrations SUCCESS 
	-- Total time: 0s 
	-- Finished at: Sun Jan 25 23:24:36 CST 2015 
	-- Final Memory: 10M/480M

```shell
$ migrate status  
```                                                                                                                                                                         
	---------------------------------------------------------
	-- MyBatis Migrations - status
	---------------------------------------------------------
	ID             Applied At          Description
	=========================================================
	20150125143145 2015-01-25 23:21:37 create changelog
	20150125143146 2015-01-25 23:24:36 first migration

```shell
mysql> select * from changelog;
```
	+----------------+---------------------+------------------+
	| id             | APPLIED_AT          | DESCRIPTION      |
	+----------------+---------------------+------------------+
	| 20150125143145 | 2015-01-25 23:21:37 | create changelog |
	| 20150125143146 | 2015-01-25 23:24:36 | first migration  |
	+----------------+---------------------+------------------+
	2 rows in set (0.00 sec)

```shell
mysql> describe users;
```
	+-------+--------------+------+-----+---------+-------+
	| Field | Type         | Null | Key | Default | Extra |
	+-------+--------------+------+-----+---------+-------+
	| id    | int(11)      | NO   | PRI | NULL    |       |
	| name  | varchar(255) | YES  |     | NULL    |       |
	+-------+--------------+------+-----+---------+-------+
	2 rows in set (0.01 sec)

Done!

###Reference
1. https://github.com/mybatis/migrations/releases
2. http://mybatis.github.io/migrations/installation.html