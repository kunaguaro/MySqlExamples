CREATE DEFINER=`root`@`localhost` PROCEDURE `createEmailList`(
	INOUT emailList varchar(4000)
)
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	declare xcompanyid BIGINT;
	DECLARE emailAddress varchar(100) DEFAULT "";
	DECLARE xmail varchar(100) DEFAULT "";
	-- declare cursor for employee email
	DEClARE curEmail 
		CURSOR FOR 	select CompanyId,CompanyEmail FROM company;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER  FOR NOT FOUND SET finished = 1;

	OPEN curEmail;

	getEmail: LOOP
		FETCH curEmail INTO xcompanyid,xmail;
		IF finished = 1 THEN 
			LEAVE getEmail;
		END IF;
		-- build email list
		SET emailList = CONCAT(xmail,";",emailList);
	END LOOP getEmail;
	CLOSE curEmail;

END


-- DROP PROCEDURE IF EXISTS proc_delete_windowbook_users_data;
CREATE PROCEDURE `proc_delete_windowbook_users_data`()
BEGIN
 
DROP TABLE IF EXISTS  records_to_delete_temp;
CREATE TEMPORARY TABLE records_to_delete_temp (
			`CompanyId` bigint NULL DEFAULT NULL ,
      `CompanyCridId` bigint NULL DEFAULT NULL   );  




	
-- ** CHECK BEFORE RUN SELECT *  DOCUMENT PROCESS WITH THIS QUERY TO SELECT 				
 INSERT INTO  records_to_delete_temp (CompanyId, CompanyCridId)  SELECT cc.CompanyID, cc.CompanyCridID FROM CompanyCrid cc WHERE cc.CompanyID IN (SELECT CompanyID FROM Company WHERE CompanyID =44);

-- TO DELETE document
 DELETE  FROM document doc WHERE doc.IncidentID in (SELECT inc.IncidentID FROM incident inc INNER JOIN records_to_delete_temp rt ON inc.CompanyCridID = rt.CompanyCridId);

-- TO DELETE incidentdetail

 DELETE  FROM incidentdetail ind WHERE ind.IncidentID IN (SELECT inc.IncidentID FROM incident inc INNER JOIN 	records_to_delete_temp rt ON inc.CompanyCridID = rt.CompanyCridId);
										
-- TO DELETE INCIDENT
   DELETE  FROM incident where  incident.CompanyCridID in (SELECT CompanyCridId FROM records_to_delete_temp);
									
-- TO DELETE KUL
		
   DELETE  from KnowUndocumentMail  where CompanyCridID in (SELECT CompanyCridId FROM records_to_delete_temp);
									
-- TO DELETE  USER
   DELETE  FROM `User` WHERE CompanyCridID in (SELECT CompanyCridId FROM records_to_delete_temp);
													
-- TO DELETE COMPANY CRID
   DELETE FROM CompanyCrid cc WHERE cc.CompanyID IN (SELECT CompanyId FROM records_to_delete_temp);   

-- TO DELETE Company
   DELETE  FROM Company WHERE CompanyID IN  (SELECT CompanyID FROM records_to_delete_temp);


-- UPDATE DIRECTORY FIELD ON DOCUMENT TABLE
   -- JUST IN CASE OF ERROR  --> UPDATE document SET Directory = REPLACE(Directory,'SuppdocPRO','Suppdoc'); 
   -- UPDATE document SET Directory = REPLACE(Directory,'Suppdoc','SuppdocPRO');

-- DELETE ALL DATA FROM TABLES

delete from `logs`;
delete from authorizelog;
delete from authorizesubscription;
delete from subscription;
/*
DROP TABLE IF EXISTS ZTest_temp;  -- ** CHECK BEFORE NOT MAPPED ON BACKEND RELEASE
DROP TABLE IF EXISTS logswebapp;  -- ** CHECK BEFORE NOT MAPPED ON BACKEND RELEASE
*/

END