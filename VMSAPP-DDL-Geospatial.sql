--DB2 for i DDL for Video Management System app
--CL:CRTLIB VMSAPP; 
--CL:DLTLIB VMSAPP;
CREATE SCHEMA VMSAPP;
--  DROP TABLE VMSAPP.VMSEVENTS;
CREATE TABLE VMSAPP.VMSEVENTS ( 
  "ID" SMALLINT GENERATED ALWAYS AS IDENTITY ( 
	START WITH 1 INCREMENT BY 1 
	NO MINVALUE NO MAXVALUE 
	CYCLE NO ORDER 
	CACHE 20 ) ,
  	OBJECTTYPE VARCHAR(250) CCSID 37 DEFAULT NULL , 
    DETECTION_SCORE NUMERIC(8, 2) DEFAULT NULL , 
    EVENT_TS TIMESTAMP DEFAULT NULL ,
    EVENT_SRC  VARCHAR(250) CCSID 37 DEFAULT NULL , 
    CONSTRAINT VMSAPP.VMSEVENTS_PK PRIMARY KEY( ID ) )  ;
    
alter table vmsapp.vmsevents add column JSON_INFO    BLOB(32K) ;   
 
/************************* JSON NoSQL with DB2 for i **********************/
 ---JSON INSERT TEST - Prior to 7.5 , use systools
  --INSERT INTO VMSAPP.VMSEVENTS(OBJECTTYPE, DETECTION_SCORE, EVENT_TS, EVENT_SRC, JSON_INFO) values('person','89.39391374588013',TIMESTAMP_FORMAT('2023-05-15 15:28:19.608', 'YYYY-MM-DD HH24:MI:SS.FF3'),'Camera1', SYSTOOLS.JSON2BSON('{
  -- "data": [  {  "id": "file.22688711f5410e6c.22688711F5410E6C!942" }]}' ));
  --- with IBM i 7.5
 INSERT INTO VMSAPP.VMSEVENTS(OBJECTTYPE, DETECTION_SCORE, EVENT_TS, EVENT_SRC, JSON_INFO) values('person','89.39391374588013',TIMESTAMP_FORMAT('2023-05-15 15:28:19.608', 'YYYY-MM-DD HH24:MI:SS.FF3'),'Camera1', JSON_TO_BSON('{
 "data": [  {  "id": "file.22688711f5410e6c.22688711F5410E6C!942" }]}' ));
 

 SELECT * FROM VMSAPP.VMSEVENTS ORDER BY ID DESC;
 
 /************************Geospatial Analytics for 7.4 / 7.5 ONLY ****************************/

 --TEST DISTANCE Computation
 CREATE VARIABLE MY_LOCATION QSYS2.ST_POINT ;
 SET MY_LOCATION = QSYS2.ST_POINT('point(-92.50365 44.05841)');
 
SELECT OBJECTTYPE, DETECTION_SCORE,  QSYS2.ST_ASTEXT(EVENT_LOCATION) AS EVENT_LOCATION, QSYS2.ST_ASTEXT(MY_LOCATION) AS MY_LOCATION, ROUND((QSYS2.ST_DISTANCE(MY_LOCATION, EVENT_LOCATION)),4) AS DISTANCE_M
FROM VMSAPP.VMSEVENTS, VMSAPP.SENSORS
ORDER BY DISTANCE_M ASC;

-- COMPUTE DISTANCE between CAMERA Events and registred employees "reference points" - for on site intervention
DROP TABLE VMSAPP.REFERENCE_LOCATIONS;
CREATE TABLE  VMSAPP.REFERENCE_LOCATIONS  ( 
  "ID" SMALLINT GENERATED ALWAYS AS IDENTITY ( 
	START WITH 1 INCREMENT BY 1 
	NO MINVALUE NO MAXVALUE 
	CYCLE ORDER 
	CACHE 20 ) ,
  	NAME VARCHAR(250) CCSID 37 DEFAULT NULL , 
    CURRENT_LOCATION QSYS2.ST_POINT);
alter table VMSAPP.REFERENCE_LOCATIONS add constraint vmsapp.id PRIMARY KEY(id);

-- SET REF POINTS LOCATIONS
 INSERT INTO VMSAPP.REFERENCE_LOCATIONS(NAME, CURRENT_LOCATION) values('EMPLOYEE-7249', QSYS2.ST_POINT('point(-92.50365 44.05841)'));
 UPDATE VMSAPP.REFERENCE_LOCATIONS set CURRENT_LOCATION=QSYS2.ST_POINT('point(-92.503 44.0053)')  where id=1; 
 
 SELECT ID,QSYS2.ST_ASTEXT(CURRENT_LOCATION) FROM VMSAPP.REFERENCE_LOCATIONS;

CREATE TABLE  VMSAPP.SENSORS  ( 
  	NAME VARCHAR(250) CCSID 37 DEFAULT NULL , 
    SENSOR_LOCATION QSYS2.ST_POINT,
    CONSTRAINT VMSAPP.SENSOR_PK1 PRIMARY KEY( NAME ) )  ;
  
 INSERT INTO VMSAPP.SENSORS(NAME,SENSOR_LOCATION) VALUES('Camera1', QSYS2.ST_POINT('point(-92.503 44.006)'));
 INSERT INTO VMSAPP.SENSORS(NAME,SENSOR_LOCATION) VALUES('Camera2', QSYS2.ST_POINT('point(-92.503 44.010)'));
 
 SELECT NAME,QSYS2.ST_ASTEXT(SENSOR_LOCATION) FROM VMSAPP.SENSORS;
 
 alter table VMSAPP.VMSEVENTS add  CONSTRAINT vmsapp.SENSOR_REF
         FOREIGN KEY (EVENT_SRC)
         REFERENCES VMSAPP.SENSORS
         ON DELETE  RESTRICT;

          
 CL: CHGAUT OBJ('/qsys.lib/VMSAPP.lib/SENSORS.file')  USER(acmeair) DTAAUT(*RWX);
 CL: CHGAUT OBJ('/qsys.lib/VMSAPP.lib/VMSEVENTS.file')  USER(acmeair) DTAAUT(*RWX);
 CL: CHGAUT OBJ('/qsys.lib/VMSAPP.lib/REFER00001.file')  USER(acmeair) DTAAUT(*RWX);
 

-- APP QUERIES examples for computation -----------------------------------------------

SELECT EVT.ID, OBJECTTYPE, DETECTION_SCORE, EVENT_TS, EVENT_SRC, QSYS2.ST_ASTEXT(SENSOR_LOCATION) AS EVENT_LOCATION, 
       QSYS2.ST_ASTEXT(CURRENT_LOCATION) AS REF_LOCATION, ROUND((QSYS2.ST_DISTANCE(CURRENT_LOCATION, SENSOR_LOCATION)),0) AS DISTANCE_M 
FROM VMSAPP.VMSEVENTS EVT,VMSAPP.SENSORS SNS, VMSAPP.REFERENCE_LOCATIONS 
WHERE EVT.EVENT_SRC = SNS.NAME AND SNS.NAME like 'Camera1'  
ORDER BY EVT.ID DESC;

INSERT INTO VMSAPP.VMSEVENTS(OBJECTTYPE, DETECTION_SCORE, EVENT_TS, EVENT_SRC) values('person','91.14156365394592',TIMESTAMP_FORMAT('2023-06-01 11:37:22.897', 'YYYY-MM-DD HH24:MI:SS.FF3'),'Camera1');

 select * from  QSYS2.ST_SPATIAL_REFERENCE_SYSTEMS ;
 
 CREATE VARIABLE ADDRESS VARCHAR(100);
 
 --GEOCODING REQUEST USA
 SET ADDRESS = URL_ENCODE('4 3rd St SW, Rochester, MN 55902');
 Values ADDRESS; 
 
 SELECT * FROM TABLE(QSYS2.HTTP_GET_VERBOSE('https://geocoding.geo.census.gov/geocoder/locations/onelineaddress','')); 
 select QSYS2.ST_ASTEXT(st_point(longitude, latitude)) as thai_pop_geo from json_table(QSYS2.HTTP_GET(
'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address='
 
 concat ADDRESS concat '&benchmark=2020&format=json', 
 '{"header":
 "User-Agent,Benoit","sslCertificateStoreFile":"/home/javaTrustStore/fromJava.KDB"}'
 ),
 'lax $.result.addressMatches[0].coordinates'
 
 columns(
longitude varchar(100) path 'lax $.x',
latitude varchar(100) path 'lax $.y'));
 
 ----Geocoding API USA https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=4+3rd+St+SW%2C+Rochester%2C+MN+55902&benchmark=2020&format=json
 
 --GEOCODING REQUEST FRANCE
  SET ADDRESS = URL_ENCODE('1 rue vieille poste, 34000 Montpellier');
 Values ADDRESS;
     
  select  longitude, latitude  from json_table(QSYS2.HTTP_GET(
'https://api-adresse.data.gouv.fr/search?q='
concat ADDRESS, 
  '{"header":"User-Agent,Benoit","sslCertificateStoreFile":"/home/javaTrustStore/fromJava.KDB"}'),
  'lax $.features[0].geometry'
 
 columns(
longitude varchar(100) path 'lax $.coordinates[0]',
latitude varchar(100) path 'lax $.coordinates[1]'));
  
  select  QSYS2.ST_ASTEXT(st_point(longitude, latitude)) as IBMMOP from json_table(QSYS2.HTTP_GET(
'https://api-adresse.data.gouv.fr/search?q='
concat ADDRESS, 
  '{"header":"User-Agent,Benoit","sslCertificateStoreFile":"/home/javaTrustStore/fromJava.KDB"}'),
  'lax $.features[0].geometry'
 
 columns(
longitude varchar(100) path 'lax $.coordinates[0]',
latitude varchar(100) path 'lax $.coordinates[1]'));
  
 -- Check result here https://geofree.fr/gf/coordinateconv.asp#listSys
 -- Geocoding API France:  https://api-adresse.data.gouv.fr/search/?q=8+bd+du+port&x=-92.503&y=44.0053
 -- FR docs http://www.postgis.fr/chrome/site/docs/workshop-foss4g/doc/geometries.html
 
  /************************ TRIGGER to DTAQ to CAMEL+Kafka  ****************************/

create or replace variable VMSAPP.DQ_EVENT clob(64000) ccsid 1208;

--  description: Create EVENT trigger 
CREATE OR REPLACE TRIGGER VMSAPP.EVENT1_TRIGGER 
	AFTER INSERT OR DELETE OR UPDATE ON VMSAPP.vmsevents 
	REFERENCING OLD AS O 
	NEW AS N 
	FOR EACH ROW 
	MODE DB2SQL 
	SET OPTION  ALWBLK = *ALLREAD , 
	ALWCPYDTA = *OPTIMIZE , 
	COMMIT = *ALL , 
	DECRESULT = (31, 31, 00) , 
	DFTRDBCOL = VMSAPP , 
	DYNDFTCOL = *NO , 
	DYNUSRPRF = *USER , 
	SRTSEQ = *HEX   
	WHEN ( INSERTING OR UPDATING OR DELETING )
 BEGIN ATOMIC 
DECLARE OPERATION VARCHAR ( 10 ) FOR SBCS DATA ; 
IF INSERTING THEN 
SET SQLP_L3.OPERATION = 'INSERT' ; 
END IF ; 
IF DELETING THEN 
SET SQLP_L3.OPERATION = 'DELETE' ; 
END IF ; 
IF UPDATING THEN 
SET SQLP_L3.OPERATION = 'UPDATE' ; 
END IF ; 
IF ( INSERTING OR UPDATING ) THEN 
SET VMSAPP.DQ_EVENT = JSON_OBJECT ( 
KEY 'table' VALUE 'vmsevents' , 
KEY 'operation' VALUE SQLP_L3.OPERATION , 
KEY 'row' VALUE JSON_OBJECT ( 
KEY 'id' VALUE N.ID , 
KEY 'objecttype' VALUE N.OBJECTTYPE , 
KEY 'detection_score' VALUE N.DETECTION_SCORE , 
KEY 'event_ts' VALUE N.EVENT_TS , 
KEY 'event_src' VALUE N.EVENT_SRC  
) 
) ; 
ELSE SET VMSAPP.DQ_EVENT = JSON_OBJECT ( 
KEY 'table' VALUE 'vmsevents' , 
KEY 'operation' VALUE SQLP_L3.OPERATION , 
KEY 'row' VALUE JSON_OBJECT ( 
KEY 'id' VALUE N.ID , 
KEY 'objecttype' VALUE N.OBJECTTYPE , 
KEY 'detection_score' VALUE N.DETECTION_SCORE , 
KEY 'event_ts' VALUE N.EVENT_TS , 
KEY 'event_src' VALUE N.EVENT_SRC 
) 
) ; 
END IF ; 
CALL QSYS2.SEND_DATA_QUEUE_UTF8 ( 
MESSAGE_DATA => VMSAPP.DQ_EVENT , 
DATA_QUEUE => 'EVENTSDQ' , 
DATA_QUEUE_LIBRARY => 'VMSAPP' 
) ; 
END  ; 

CL: CRTDTAQ DTAQ(VMSAPP/EVENTSDQ) MAXLEN(64512) SEQ(*LIFO) SIZE(*MAX2GB);

SELECT * FROM TABLE(QSYS2.DATA_QUEUE_ENTRIES(
           DATA_QUEUE => 'EVENTSDQ',
           DATA_QUEUE_LIBRARY => 'VMSAPP')) ;
  
 SELECT * FROM VMSAPP.VMSEVENTS ORDER BY ID DESC;
